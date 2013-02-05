# encoding: UTF-8

require 'free_cite/preprocessor'
require 'free_cite/postprocessor'
require 'free_cite/token_features'
require 'tempfile'
require 'nokogiri'
require 'cgi'
require 'pry'

module FreeCite

  class CRFParser

    attr_reader :feature_order
    attr_reader :token_features

    include TokenFeatures
    include Preprocessor
    include Postprocessor

    DIR = File.dirname(__FILE__)
    TAGGED_REFERENCES = "#{DIR}/resources/trainingdata/tagged_references.txt"
    TAGGED_HTML_REFERENCES = "#{DIR}/resources/trainingdata/tagged_html_references.txt"
    TRAINING_DATA = "#{DIR}/resources/trainingdata/training_data.txt"
    MODEL_FILE = "#{DIR}/resources/model"
    HTML_MODEL_FILE = "#{DIR}/resources/html_model"
    TEMPLATE_FILE = "#{DIR}/resources/parsCit.template"

    # Feature functions must be performed in alphabetical order, since
    # later functions may depend on earlier ones.
    # If you want to specify a specific output order, do so in a yaml file in
    # config. See ../../config/parscit_features.yml as an example
    # You may also use this config file to specify a subset of features to use
    # Just be careful not to exclude any functions that included functions
    # depend on
    def initialize(mode=:string, config_file="#{DIR}/../../config/parscit_features.yml")
      @mode = mode

      if config_file
        f = File.open(config_file, 'r')
        hsh = YAML::load( f )
        @feature_order = hsh["feature_order"].map(&:to_sym)
        @token_features = hsh["feature_order"].sort.map(&:to_sym)
      else
        @token_features = (TokenFeatures.instance_methods).sort.map(&:to_sym)
        @token_features.delete :clear
        @feature_order = @token_features
      end
    end

    def model
      @model ||= CRFPP::Tagger.new("-m #{default_model_file} -v 1");
    end

    def parse_string(str, presumed_author=nil)
      raw_string = str.dup
      str = normalize_cite_text(str)

      toks, features = str_2_features(str, false, presumed_author)
      tags, overall_prob, tag_probs = eval_crfpp(features, model)

      ret = {}
      tags.each_with_index { |t, i| (ret[t] ||= []) << toks[i] }
      ret.each { |k, v| ret[k] = v.join(' ') }

      normalize_fields(ret)
      ret['raw_string'] = raw_string
      [ret, overall_prob, tag_probs]
    end

    def eval_crfpp(feat_seq, model)
      model.clear
      feat_seq.each {|vec|
        line = vec.join(" ").strip
        raise unless model.add(line)
      }
      raise unless model.parse
      tags = []
      probs = {}
      feat_seq.length.times {|i|
        tags << model.y2(i)
        probs[model.y2(i)] ||= 1
        probs[model.y2(i)] *= model.prob(i)
      }
      [tags, model.prob, probs]
    end

    def self.strip_punct(str)
      toknp = str.gsub(/[^\w]/, '')
      toknp = "EMPTY" if toknp.blank? # TODO Seems maybe hacky
      toknp
    end

    def normalize_input_author(str)
      return nil if str.blank?
      str.split.map(&:downcase).map { |t| self.class.strip_punct(t) }
    end

    def prepare_token_data(cstr, training=false)
      cstr.strip!

      if training
        tags = Nokogiri::HTML.fragment(cstr).children
        tokens = tags.inject([]) do |tokens, tag|
          tokens += prepare_token_data_with_tag(CGI.unescapeHTML(tag.inner_html), tag.name)
        end
      else
        tokens = prepare_token_data_with_tag(cstr)
      end

      self.clear

      return tokens
    end

    def prepare_token_data_with_tag(str, label=nil)
      if @mode == :html
        html = Nokogiri::HTML.fragment(str)
        toks = prepare_html_token_data(html)
      elsif @mode == :string
        toks = prepare_text_token_data(str)
      end

      toks.reject! { |t| t.empty? }

      if label
        toks.each { |t| t.label = label }
      end

      toks
    end

    def prepare_html_token_data(html)
      if html.text?
        raw_toks = html.text.split(/[[:space:]]+/)
        raw_toks.each_with_index.map { |t,i| Token.new(t, html, i, raw_toks.length) }
      else
        tokens = []
        html.traverse do |node|
          tokens += prepare_html_token_data_with_tag(node)
        end
      end
    end

    def prepare_text_token_data(text)
      text.split(/[[:space:]]+/).map { |s| Token.new(s) }
    end

    # calculate features on the full citation string
    def str_2_features(cstr, training=false, presumed_author=nil)
      features = []
      tokens = prepare_token_data(cstr, training)
      author_names = normalize_input_author(presumed_author)

      tokens.each_with_index do |tok, toki|
        raise "All tokens must be labeled" if training && tok.label.nil?

        feats = {}

        @token_features.each {|f|
          feats[f] = self.send(f, tokens, toki, author_names)
        }

        features << [tok.raw]
        @feature_order.each {|f| features.last << feats[f]}
        features.last << tok.label if training
      end

      [tokens.map(&:raw), features]
    end

    def write_training_file(tagged_refs=nil, training_data=TRAINING_DATA)
      tagged_refs ||= default_tagged_references

      fin = File.open(tagged_refs, 'r')
      fout = File.open(training_data, 'w')
      x = 0
      while l = fin.gets
        _, data = str_2_features(l.strip, true)
        data.each {|line| fout.write("#{line.join(" ")}\n") }
        fout.write("\n")
      end

      fin.close
      fout.flush
      fout.close
    end

    def train(tagged_refs=nil, model=nil, template=TEMPLATE_FILE, training_data=nil)
      tagged_refs ||= default_tagged_references
      model ||= default_model_file

      if training_data.nil?
        training_data = TRAINING_DATA
        write_training_file(tagged_refs, training_data)
      end

      `crf_learn #{template} #{training_data} #{model}`
    end

    def default_tagged_references
      if @mode == :string
        TAGGED_REFERENCES
      elsif @mode == :html
        TAGGED_HTML_REFERENCES
      else
        raise "Unknown mode: #{@mode}"
      end
    end

    def default_model_file
      if @mode == :string
        MODEL_FILE
      elsif @mode == :html
        HTML_MODEL_FILE
      else
        raise "Unknown mode: #{@mode}"
      end
    end

  end

  class TrainingError < Exception; end

  class Token

    attr_reader :node, :idx_in_node, :node_token_count
    attr_accessor :label

    def initialize(str, node=nil, idx_in_node=nil, node_token_count=nil)
      @str = str
      @node = node
      @idx_in_node = idx_in_node
      @node_token_count = node_token_count
    end

    def raw
      @str
    end

    def np
      @np ||= CRFParser.strip_punct(@str)
    end

    def lcnp
      @lcnp ||= np == "EMPTY" ? np : np.downcase
    end

    def empty?
      raw.strip.blank?
    end

  end

end

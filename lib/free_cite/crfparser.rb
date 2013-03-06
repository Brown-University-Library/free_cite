# encoding: UTF-8

require 'tempfile'
require 'nokogiri'
require 'cgi'
require 'engtagger'

module Excite

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
    HTML_TEMPLATE_FILE = "#{DIR}/resources/html.template"
    CONFIG_FILE = "#{DIR}/../../config/parscit_features.yml"

    # Feature functions must be performed in alphabetical order, since
    # later functions may depend on earlier ones.
    # TODO This seems pretty confusing and dependent on the current features.
    def initialize(mode=:string)
      @mode = mode

      f = File.open(CONFIG_FILE, 'r')
      hsh = YAML::load(f)[mode.to_s]
      @feature_order = hsh["feature_order"].map(&:to_sym)
      @token_features = hsh["feature_order"].sort.map(&:to_sym)
    end

    def model
      @model ||= CRFPP::Tagger.new("-m #{default_model_file} -v 1");
    end

    def parse(str, presumed_author=nil)
      raw_string = str.dup

      toks, features = str_2_features(str, false, presumed_author)
      tags, overall_prob, tag_probs = eval_crfpp(features, model)

      ret = {}
      tags.each_with_index { |t, i| (ret[t] ||= []) << toks[i].for_join(toks[i-1]) }
      ret.each { |k, v| ret[k] = v.join('').strip }

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
      str.split.map(&:downcase).map{ |t| self.class.strip_punct(t) }.select{ |s| s.length > 2 }
    end

    def prepare_token_data(raw_string, training=false)
      if training
        tags = tagged_string_2_tags(raw_string.strip)

        labels, raw_string, joined_tokens = [], '', ''
        tags.each do |tag|
          raw = CGI.unescapeHTML(tag.inner_html)

          label = tag.name
          raise "Invalid label #{label} for:\n#{str}" if label.present? && !recognized_labels.include?(label)

          toks = str_2_tokens(raw)

          labels << [label, joined_tokens.length]
          joined_tokens += toks.map(&:raw).join
          raw_string += "\n#{raw}"
        end
      end

      tokens = str_2_tokens(raw_string.strip)

      if training
        joined_tokens = ''
        label, _ = labels.shift
        next_label, end_idx = labels.shift unless labels.empty?

        tokens.each do |tok|
          tok.label = label
          joined_tokens += tok.raw
          if joined_tokens.length == end_idx
            label = next_label
            next_label, end_idx = labels.shift unless labels.empty?
          elsif joined_tokens.length > end_idx && !labels.empty?
            raise "Tokens do not match labels"
          end
        end
        raise "Unused label" unless labels.empty?
      end

      self.clear

      return tokens
    end

    def tagger
      @tagger ||= EngTagger.new
    end

    def tagged_string_2_tags(str)
      str = "<string>#{str}</string>"
      node = Nokogiri::XML.fragment(str).css('string')
      node.children.reject(&:text?)
    end

    def str_2_tokens(str)
      if @mode == :html
        toks = html_str_2_tokens(str)
      elsif @mode == :string
        toks = text_str_2_tokens(str)
      end

      toks.reject { |t| t.empty? }
    end

    def recognized_labels
      if @mode == :string
        ["author", "title", "editor", "booktitle", "date", "journal", "volume", "institution", "pages", "location", "publisher", "note", "tech"]
      elsif @mode == :html
        ["author", "title", "editor", "booktitle", "date", "journal", "volume", "institution", "pages", "location", "publisher", "note", "workid", "link", "bullet"]
      else
        []
      end
    end

    def html_str_2_tokens(str)
      html = Nokogiri::HTML.fragment(str.gsub('>', '> ')) # gsub to ensure strings in separate tags are always separate tokens even if HTML is bad

      tokens = []
      html.traverse do |node|
        tokens += html_text_node_2_tokens(node) if node.text?
      end
      tokens
    end

    def html_text_node_2_tokens(node)
      text = CGI.unescapeHTML(node.text)
      return [] if text.blank?

      tokens = text_str_2_tokens(text)
      tokens.each_with_index { |tok, i| tok.is_in_node!(node, i, tokens.length) }
      tokens
    end

    def text_str_2_tokens(text)
      tagged = tagger.add_tags(normalize_citation(text))
      tags = tagged_string_2_tags(tagged.gsub('&','&amp;')) # EngTagger has legitimately added angle brackets which are meaningful in XML, but angle-brackets predate EngTagger and are semantic
      tags.map { |tag| Token.new(tag.text, tag.name) }
    end

    # calculate features on the full citation string
    def str_2_features(raw_string, training=false, presumed_author=nil)
      features = []
      tokens = prepare_token_data(raw_string, training)

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

      [tokens, features]
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

    def train(tagged_refs=nil, model=nil, template=nil, training_data=nil)
      tagged_refs ||= default_tagged_references
      model ||= default_model_file
      template ||= default_template_file

      if training_data.nil?
        training_data = TRAINING_DATA
        write_training_file(tagged_refs, training_data)
      end

      `crf_learn #{template} #{training_data} #{model} -f3 1>&2`
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

    def default_template_file
      if @mode == :string
        TEMPLATE_FILE
      elsif @mode == :html
        HTML_TEMPLATE_FILE
      else
        raise "Unknown mode: #{@mode}"
      end
    end

  end

  class TrainingError < Exception; end

  class Token

    attr_reader :node, :idx_in_node, :node_token_count, :part_of_speech
    attr_accessor :label

    def initialize(str, part_of_speech=nil)
      @str = str
      @part_of_speech = part_of_speech
    end

    def is_in_node!(node, idx_in_node, node_token_count)
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

    def to_s
      "{#{raw}}"
    end

    def for_join(prev)
      if ['pp','ppc','ppr','pps','rrb', 'pos'].include?(part_of_speech)
        raw
      elsif prev && ['ppd','ppl','lrb'].include?(prev.part_of_speech)
        raw
      else
        " "+raw
      end
    end
  end

end

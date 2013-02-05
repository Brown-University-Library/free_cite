# encoding: UTF-8

require 'active_support/core_ext/object'
require 'crfpp'
require 'free_cite/crfparser'

module FreeCite

  # parse a string into a citation
  # optionally pass the presumed author
  def self.parse_string(str, author=nil)
    if str.present?
      Citation.new(str, string_parser, author)
    end
  end

  class << self
    alias_method :parse, :parse_string # for backwards compatibility
  end

  def self.parse_html(html, author=nil)
    if html.present?
      Citation.new(html, html_parser, author)
    end
  end

private

  def self.string_parser
    Thread.current[:string_crf_parser] ||= CRFParser.new(:string)
  end

  def self.html_parser
    Thread.current[:html_crf_parser] ||= CRFParser.new(:html)
  end

  class Citation < Hash

    attr_accessor :probabilities, :overall_probability

    def initialize(str, parser, author=nil)
      raw_hash, overall_prob, tag_probs = parser.parse(str, author)
      self.replace(raw_hash.symbolize_keys)
      @probabilities = tag_probs.symbolize_keys
      @overall_probability = overall_prob
    end

    # TODO confusing that we have this but no helpers for actual values (or probabilities) - fix this
    def method_missing(method_name)
      if (md = method_name.to_s.match /^has_(\w+)\?$/)
        has_field?(md[1].to_sym)
      else
        super
      end
    end

    def has_field?(field)
      value = self[field]
      value.present? && value != self[:raw_string].strip && value.to_s.scan(/["”“]/).length != 1 # if the field has exactly one double quote, it's a good sign we didn't parse successfully TODO Move to postprocessor or out of gem
    end

  end

end

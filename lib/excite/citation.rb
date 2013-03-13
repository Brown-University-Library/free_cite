# encoding: UTF-8

require 'active_support/core_ext/object'

module Excite

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

  end

end

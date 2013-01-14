# encoding: UTF-8

require 'active_support/core_ext/object'
require 'crfpp'
require 'free_cite/crfparser'

class Citation < Hash

  attr_accessor :probabilities, :overall_probability

  def self.parse(str)
    if str.present?
      Citation.new(str)
    end
  end

  def self.parser
    @parser ||= CRFParser.new
  end

  def initialize(str)
    raw_hash, overall_prob, tag_probs = self.class.parser.parse_string(str) || {}
    self.replace(raw_hash.symbolize_keys)
    @probabilities = tag_probs.symbolize_keys
    @overall_probability = overall_prob
  end

  def method_missing(method_name)
    if (md = method_name.to_s.match /^has_(\w+)\?$/)
      has_field?(md[1].to_sym)
    else
      super
    end
  end

private

  def has_field?(field)
    value = self[field]
    value.present? && value != self[:raw_string].strip && value.to_s.scan(/["”“]/).length != 1 # if the field has exactly one double quote, it's a good sign we didn't parse successfully
  end

end

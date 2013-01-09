# encoding: UTF-8

require 'active_support/core_ext/object'
require 'crfpp'
require 'free_cite/crfparser'

class Citation

  def self.parse(str)
    return unless str.present?
    hash = self.parser.parse_string(str).symbolize_keys
    hash if self.valid_reference?(hash)
  end

  def self.parser
    @parser ||= CRFParser.new
  end

  def self.valid_reference?(hash)
    hash[:title].present? && hash[:raw_string] != hash[:title] && hash[:year].present?
  end

end

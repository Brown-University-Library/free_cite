# encoding: UTF-8

require 'active_support/core_ext/object'
require 'crfpp'
require 'free_cite/crfparser'

class Citation < Hash

  MaxSaneTitleLength = 256

  def self.parse(str)
    if str.present?
      citation = Citation.new(str)
      citation if citation.valid?
    end
  end

  def self.parser
    @parser ||= CRFParser.new
  end

  def initialize(str)
    transformed_versions_to_try(str).each do |v|
      raw_hash = self.class.parser.parse_string(v) || {}
      replace!(raw_hash.symbolize_keys)
      break if valid?
    end
  end

  def valid?
    has_title? && (has_author? || has_year?)
  end

  def has_title?
    has_field?(:title) && self[:title].length < MaxSaneTitleLength
  end

  def has_author?
    has_field?(:authors)
  end

  def has_year?
    has_field?(:year)
  end

private

  alias_method :replace!, :replace

  def has_field?(field)
    self[field].present? && self[field] != self[:raw_string]
  end

  def transformed_versions_to_try(str)
    [str]
  end

end

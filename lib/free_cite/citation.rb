# encoding: UTF-8

require 'active_support/core_ext/object'
require 'crfpp'
require 'free_cite/crfparser'

class Citation

  def self.parse(str)
    return unless str.present?

    self.transformed_versions_to_try(str).each do |v|
      hash = (self.parser.parse_string(str) || {}).symbolize_keys
      return hash if self.valid_reference?(hash)
    end

    nil
  end

  def self.parser
    @parser ||= CRFParser.new
  end

  def self.valid_reference?(hash)
    hash && hash[:title].present? && hash[:raw_string] != hash[:title] && hash[:year].present?
  end

  # skeleton for hack: apply some rules to cover cases which the model doesn't
  def self.transformed_versions_to_try(str)
    [str].compact.uniq
  end

  def self.truncate_journal(str)
    if (m = str.match /(.+)\.(\s\w)+,\s+(vol\.?)?\s*(\d\.)+\s*\((\d\.)+\)/)
      m[1]
    end
  end

end

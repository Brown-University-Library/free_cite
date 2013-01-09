# encoding: UTF-8

require 'active_support/core_ext/object'
require 'crfpp'
require 'crfparser'

module FreeCite

  def self.parse(str)
    self.parser.parse_string(str).symbolize_keys
  end

  def self.parser
    @parser ||= CRFParser.new
  end

end

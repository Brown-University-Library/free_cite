# encoding: UTF-8

require 'rake'
require 'bundler/gem_tasks'
require 'rspec/core/rake_task'
require 'free_cite'

RSpec::Core::RakeTask.new :spec

namespace :crfparser do
  desc 'train a CRF model for the citation parser'
  task :train_model do
    CRFParser.new.train
  end
end


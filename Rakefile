# encoding: UTF-8

require 'rake'
require 'bundler/gem_tasks'
require 'rspec/core/rake_task'
require 'free_cite'

RSpec::Core::RakeTask.new :spec

namespace :crfparser do
  desc 'train a CRF model for the citation parser'
  task :train_model do
    FreeCite::CRFParser.new.train
  end

  desc 'test a CRF model with the current training set & features'
  task :test_model do
    require "#{File.dirname(__FILE__)}/model/test/model_test"
    FreeCite::ModelTest.new.run_test
  end
end


# encoding: UTF-8

require 'rake'
require 'bundler/gem_tasks'
require 'rspec/core/rake_task'
require 'free_cite'

RSpec::Core::RakeTask.new :spec

namespace :crfparser do
  desc 'train a CRF model for the citation parser'
  task :train_model, :type do |_, args|
    mode = args[:type] ? args[:type].to_sym : :string
    FreeCite::CRFParser.new(mode).train
  end

  desc 'test a CRF model with the current training set & features'
  task :test_model, :type do |_, args|
    require "#{File.dirname(__FILE__)}/model/test/model_test"
    mode = args[:type] ? args[:type].to_sym : :string
    FreeCite::ModelTest.new(mode).run_test
  end
end

desc "Tag #{Bundler::GemHelper.new.send(:version_tag)}, build and push to gemfury"
task :release_internal do |t|
  require 'gemfury'

  class ReleaseInternalGem < Bundler::GemHelper
    def release_gem
      guard_clean
      built_gem_path = build_gem
      if Bundler::VERSION =~ /1\.3\.\d/
        tag_version { git_push } unless already_tagged?
      else
        guard_already_tagged
        tag_version { git_push }
      end
      `fury push #{built_gem_path}`
      Bundler.ui.confirm "Pushed #{name} #{version} to gemfury"
    end
  end

  ReleaseInternalGem.new.release_gem
end

module Bundler
  class GemHelper
    def release_gem
      raise 'STOP. This is an internal gem. Use `rake release_internal` instead'
    end
  end
end
# encoding: utf-8
$:.push File.expand_path("../lib", __FILE__)

require 'bundler'
require 'bundler/setup'
require 'thor/rake_compat'

class Default < Thor
  include Thor::RakeCompat
  Bundler::GemHelper.install_tasks

  desc "build", "Build Solve-#{Solve::VERSION}.gem into the pkg directory"
  def build
    Rake::Task["build"].invoke
  end

  desc "install", "Build and install Solve-#{Solve::VERSION}.gem into system gems"
  def install
    Rake::Task["install"].invoke
  end

  desc "release", "Create tag v#{Solve::VERSION} and build and push Solve-#{Solve::VERSION}.gem to Rubygems"
  def release
    Rake::Task["release"].invoke
  end

  desc "spec", "Run RSpec code examples"
  def spec
    exec "rspec --color --format=documentation spec"
  end

  desc "spec", "Run RSpec code examples"
  def nogecode_spec
    exec "rspec -t '~gecode' --color --format=documentation spec"
  end
end

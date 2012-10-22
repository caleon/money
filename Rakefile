# encoding: utf-8

require 'rubygems'
require 'bundler'
begin
  Bundler.setup(:default, :development)
rescue Bundler::BundlerError => e
  $stderr.puts e.message
  $stderr.puts "Run `bundle install` to install missing gems"
  exit e.status_code
end
require 'rake'

require 'jeweler'
Jeweler::Tasks.new do |gem|
  # gem is a Gem::Specification... see http://docs.rubygems.org/read/chapter/20 for more options
  gem.name = "money"
  gem.homepage = "http://github.com/caleon/money"
  gem.license = "MIT"
  gem.summary = %Q{Ruby class for representing Money with currencies for use with Rails and ActiveRecord}
  gem.description = <<-DESC
    This is a representation of Money (and various arbitrary currencies),
    created with usage within the Rails framework in mind, although it can
    stand alone as long as you are okay with including ActiveModel for
    validations and a few ActiveSupport helpers (although those can be handled
    differently if there is enough desire to decouple this from those
    dependencies).

    Its greatest utility will come when used with ActiveRecord objects
    stored as database rows, where combined with ActiveRecord's `composed_of`
    statement, you are able to separate the tedious money-related logic
    within your classes which utilize the abstraction.

    Out of convenience, this is written for Ruby 1.9, although there shouldn't
    be many changes required ot make this 1.8 compatible. RCov is not listed
    as a dependency since 1.9 setups should use simplecov instead.
  DESC
  gem.email = "caleon@gmail.com"
  gem.authors = ["caleon"]
  # dependencies defined in Gemfile
end
Jeweler::RubygemsDotOrgTasks.new

require 'rspec/core'
require 'rspec/core/rake_task'
RSpec::Core::RakeTask.new(:spec) do |spec|
  spec.pattern = FileList['spec/**/*_spec.rb']
end

RSpec::Core::RakeTask.new(:rcov) do |spec|
  spec.pattern = 'spec/**/*_spec.rb'
  spec.rcov = true
end

task :default => :spec

require 'rdoc/task'
Rake::RDocTask.new do |rdoc|
  version = File.exist?('VERSION') ? File.read('VERSION') : ""

  rdoc.rdoc_dir = 'rdoc'
  rdoc.title = "money #{version}"
  rdoc.rdoc_files.include('README*')
  rdoc.rdoc_files.include('lib/**/*.rb')
end

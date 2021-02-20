require 'rubygems'
require 'bundler/setup'
require 'rspec/core'
require 'rspec/core/rake_task'
require 'yard'

RSpec::Core::RakeTask.new(:spec) do |spec|
  spec.rspec_opts = ['--backtrace '] if ENV['DEBUG']
    spec.verbose = true
end

desc 'Default: run the unit tests.'
task default: [:all]

desc 'Test the plugin under all supported Rails versions.'
task :all do |_t|
    exec('bundle exec rspec')
end

# dirty hack for YardocTask
::Rake.application.class.class_eval do
  alias_method :last_comment, :last_description
end

YARD::Config.options[:load_plugins] = true
YARD::Config.load_plugins

YARD::Rake::YardocTask.new do |t|
  t.files = %w[lib/**/*.rb spec/**/*_spec.rb] # optional
  t.options = %w[--any --extra --opts --markup-provider=redcarpet --markup=markdown --debug] # optional
  t.stats_options = ['--list-undoc'] # optional
end

task :docs do
  exec('bundle exec yard --list-undoc')
end

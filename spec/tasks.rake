require 'rubygems'
require 'bundler/setup'
require 'rspec/core'
require 'rspec/core/rake_task'
require 'coveralls/rake/task'
Coveralls::RakeTask.new

RSpec::Core::RakeTask.new(:spec) do |spec|
  spec.rspec_opts = ['--backtrace '] if ENV['DEBUG']
end

desc 'Default: run the unit tests.'
task default: [:all]

desc 'Test the plugin under all supported Rails versions.'
task :all do |_t|
  if ENV['TRAVIS']
    exec(' bundle exec rspec  && bundle exec rake coveralls:push')
  else
    exec('bundle exec rspec')
  end
end

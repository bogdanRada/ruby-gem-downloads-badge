require 'bundler/setup'
require 'rspec/core/rake_task'
require 'coveralls/rake/task'
require 'yard'
require 'yard-rspec'
Coveralls::RakeTask.new

RSpec::Core::RakeTask.new(:spec) do |spec|
  spec.rspec_opts = ['--backtrace '] if ENV['DEBUG']
end

desc 'Default: run the unit tests.'
task default: [:all]

desc 'Test the plugin under all supported Rails versions.'
task :all do |_t|
  if ENV['TRAVIS']
    exec(' bundle exec phare &&  bundle exec rspec  && bundle exec rake coveralls:push')
  else
    exec(' bundle exec rubocop -a . && bundle exec phare && bundle exec rspec')
  end
end

YARD::Config.options[:load_plugins] = true
YARD::Config.load_plugins

YARD::Rake::YardocTask.new do |t|
  t.files = ['web.rb', 'config/**/*.rb', 'lib/**/*.rb', 'spec/**/*_spec.rb'] # optional
  t.options = ['--any', '--extra', '--opts', '--markup-provider=redcarpet', '--markup=markdown', '--debug'] # optional
  t.stats_options = ['--list-undoc'] # optional
end

task :docs do
  exec(' bundle exec rubocop -a .  && bundle exec phare  && bundle exec inch --pedantic && bundle exec yard')
end

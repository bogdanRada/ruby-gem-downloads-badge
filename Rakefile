require 'rubygems'
require 'bundler/setup'
require 'rake'
require 'rake/clean'
require 'rake/testtask'
require_relative './lib/web'
if %w(test development).include?(ENV['RACK_ENV'])
  load './spec/tasks.rake'
end

require 'rubygems'
require 'bundler/setup'
require 'rake'
require 'rake/clean'
require 'rake/testtask'
require_relative './config/application.rb'
if %w(test development).include?(ENV['RACK_ENV'])
  load './spec/tasks.rake'
end

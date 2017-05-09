require 'rubygems'
require 'bundler/setup'
require 'rake'
require 'rake/clean'
require 'rake/testtask'
require_relative './lib/web'
if %w(test development).include?(ENV['RACK_ENV']) ||  %w(test development).include?(ENV['APP_ENV'])
  load './spec/tasks.rake'
end

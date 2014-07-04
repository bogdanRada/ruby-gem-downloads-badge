#!/usr/bin/env ruby
require 'rubygems'
require "bundler"
Bundler.require :default, (ENV["RACK_ENV"] || "development").to_sym

require 'erb'
require_relative './badge_downloader'


class RubygemsDownloadShieldsApp < Sinatra::Base
  register(Sinatra::Cache)
   
  set :cache_enabled, true 
  
  set :static, true                             # set up static file routing
  set :public_folder, File.expand_path('..', __FILE__) # set up the static dir (with images/js/css inside)
  
  set :views,  File.expand_path('../views', __FILE__) # set up the views dir
  
  
  before do
    content_type "image/svg+xml; Connection: keep-alive; Content-Encoding: gzip; charset=utf-8"
  end
  
  get '/?:gem?/?:version?'  do
    @downloader = BadgeDownloader.new( params)
    return @downloader.download_shield
  end

  
end

  


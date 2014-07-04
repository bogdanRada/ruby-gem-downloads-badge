#!/usr/bin/env ruby
require 'rubygems'
require 'sinatra'
require 'sinatra/cache'
require 'redis-sinatra'

require 'em-http-request'
require "faraday"
require 'faraday-http-cache'
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
    @downloader.download_shield
  end

  
end

  


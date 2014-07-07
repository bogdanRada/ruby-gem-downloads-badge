#!/usr/bin/env ruby
require 'rubygems'
require "bundler"
Bundler.require :default, (ENV["RACK_ENV"] || "development").to_sym

require_relative './badge_downloader'
require 'sinatra/contrib/all'
require 'rack'

class RubygemsDownloadShieldsApp < Sinatra::Base
  helpers Sinatra::Streaming
   
  set :cache_enabled, true 
  
  set :static, true                             # set up static file routing
  set :public_folder, File.expand_path('../static', __FILE__)# set up the static dir (with images/js/css inside)
  
  set :views,  File.expand_path('../views', __FILE__) # set up the views dir
  
  
  before do
    content_type "image/svg+xml; Connection: keep-alive; Content-Encoding: gzip; charset=utf-8"
  end

  get '/?:gem?/?:version?'  do
    if !params[:gem].nil? &&  params[:gem].include?("favicon")
       send_file File.join(settings.public_folder, "favicon.ico"), :disposition => 'inline', :type => "image/x-icon"
     else
      stream :keep_open do |out|           
        EM.run do
          @downloader = BadgeDownloader.new( params, out)
          @downloader.download_shield
        end
        EM.error_handler{ |e|
          puts   " Error raised during event loop: #{e.message}"
        }
      end
      
    end
  end

end

  


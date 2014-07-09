#!/usr/bin/env ruby
require 'rubygems'
require "bundler"
Bundler.require :default, (ENV["RACK_ENV"] || "development").to_sym

require 'sinatra/streaming'
require "sinatra/json"
require 'json'
require 'securerandom'
require 'versionomy'
require_relative './config/initializers/version_sort'

require_relative './badge_downloader'
require_relative './rubygems_api'

class RubygemsDownloadShieldsApp < Sinatra::Base
  helpers Sinatra::Streaming
   
  
  set :static_cache_control, [:no_cache, :must_revalidate, :max_age => 0]
  set :static, false                            # set up static file routing
  set :public_folder, File.expand_path('../static', __FILE__)# set up the static dir (with images/js/css inside)
  
  set :views,  File.expand_path('../views', __FILE__) # set up the views dir
  
  
  before do
    content_type "image/svg+xml;  Content-Encoding: gzip; charset=utf-8; "
    headers({"Pragma" => "no-cache"})
#    etag SecureRandom.hex
#    last_modified(Time.now - 60)
    expires Time.now - 1, :no_cache, :must_revalidate, :max_age => 0
  end

  get '/?:gem?/?:version?'  do
    
    if !params[:gem].nil? &&  params[:gem].include?("favicon")
      send_file File.join(settings.public_folder, "favicon.ico"), :disposition => 'inline', :type => "image/x-icon"
    else
      stream :keep_open do |out|  
        EM.run { 
          @downloader = BadgeDownloader.new( params, out)
          @downloader.fetch_image_badge_svg
        }
        EM.error_handler{|e| puts "Error during event loop : #{e.inspect}" }
      end
    end
  end

end

  


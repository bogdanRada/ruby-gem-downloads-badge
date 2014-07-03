#!/usr/bin/env ruby
require 'rubygems'
require 'sinatra'
require 'em-http-request'
require "faraday"
require 'faraday-http-cache'
require 'versionomy'
require 'haml'
require 'erb'
require 'sinatra/cache'
require 'redis-sinatra'

class SingingRain < Sinatra::Base
  register(Sinatra::Cache)

  set :cache_enabled, true 
  
  set :static, true                             # set up static file routing
  set :public, File.expand_path('..', __FILE__) # set up the static dir (with images/js/css inside)
  
  set :views,  File.expand_path('../views', __FILE__) # set up the views dir
  
  # Your "actions" go here…
  #

  
  before do
    content_type "image/svg+xml; Connection: keep-alive; Content-Encoding: gzip; charset=utf-8"
  end
  
  get '/?:gem?/?:version?'  do
    initialize_default_settings
    initialize_faraday_connection
  
    
    if (!@gem_name.nil?  && @gem_version.nil?)
    
      make_rubygem_http_request("/api/v1/gems/#{@gem_name}.json") do  |http_response|
        @downloads_count = http_response['version_downloads']
        @downloads_count = "#{http_response['downloads']}_total" if params[:type].present? && params[:type] == "total"
      end
      
    elsif (!@gem_name.nil?  && !@gem_version.nil? && @gem_version!= "stable" && @error_parse_gem_version == false)
      
      make_rubygem_http_request("/api/v1/downloads/#{@gem_name}-#{@gem_version}.json") do  |http_response|
        @downloads_count = http_response['version_downloads']
        @downloads_count = "#{http_response['total_downloads']}_total" if params[:type].present? && params[:type] == "total"
      end
     
    elsif (!@gem_name.nil?  && !@gem_version.nil? && @gem_version== "stable" && @error_parse_gem_version == false)
      
      make_rubygem_http_request("/api/v1/versions/#{@gem_name}.json") do  |http_response|
        versions =  http_response.select{ |val|  val['prerelease'] == false } if http_response.present?
        version_numbers =  versions.map{|val| val['number'] } if versions.present?
        sorted_versions = version_numbers.version_sort if versions.present?
        last_version_number =  sorted_versions.present? ? sorted_versions.last : ""
        last_version_details = versions.detect {|val| val['number'] == last_version_number } if last_version_number.present?
        @downloads_count = last_version_details['downloads_count'] if last_version_number.present?
      end
    
    else
      render_badge_image
    end
  end
  
  
  private
  
  def render_badge_image
    @downloads_count = 0 if @downloads_count.nil?
    initialize_shields_faraday_connection
    resp = @badge_conn.get do |req|
      req.url "/badge/downloads-#{@downloads_count}-#{@color}.svg#{@style}"
      req.headers['Content-Type'] = "image/svg+xml; Connection: keep-alive; Content-Encoding: gzip; charset=utf-8"
      req.options.timeout = 5           # open/read timeout in seconds
      req.options.open_timeout = 2
    end
    resp.on_complete {
      @image_svg = resp.body 
      return @image_svg
    }
  end
    
  def initialize_default_settings
    @gem_name = params[:gem].nil? ? nil : params[:gem] ;
    @gem_version = params[:version].nil? ? nil : params[:version] ;
    @color = params[:color].nil? ? "blue" : params[:color] ;
    @style =  params[:style].nil? ? nil: params[:style]; 
    @style = '?style=flat'  if @style == "flat"
    @downloads_count = nil
    @error_parse_gem_version = false
    parse_gem_version
  end
  
  
  def parse_gem_version
    if !@gem_version.nil? &&  @gem_version!= "stable"
      begin
        Versionomy.parse(@gem_version)
      rescue Versionomy::Errors::ParseError
        @color = "lightgrey";
        @downloads_count = "invalid";
        @error_parse_gem_version = true
      end
    end
  end
  
  def  initialize_shields_faraday_connection
    @badge_conn = Faraday.new "http://img.shields.io" do |con|
      con.request :url_encoded
      con.response :logger
      con.adapter :net_http
      #   con.use Faraday::HttpCache, store: RedisStore
    end
  end
  
  
  def initialize_faraday_connection
    @conn = Faraday.new "https://rubygems.org", :ssl => {:verify => false } do |con|
      con.request :url_encoded
      con.response :logger
      con.adapter :net_http
      # con.use Faraday::HttpCache, store: RedisStore
    end
  end
  
  def make_rubygem_http_request(custom_url)
    resp = @conn.get do |req|
      req.url custom_url
      req.headers['Content-Type'] = 'application/json'
      req.options.timeout = 5           # open/read timeout in seconds
      req.options.open_timeout = 2
    end
    resp.on_complete {
      @res = resp.body 
      @res = JSON.parse(@res)
      yield @res if block_given?
      return render_badge_image
          
      #request.env['async.callback'].call(response)
    }
  end  
  
 
  

  
end

  


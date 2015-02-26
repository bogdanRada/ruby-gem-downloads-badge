require 'rubygems'
require "bundler"
Bundler.require :default, (ENV["RACK_ENV"] || "development").to_sym
require 'active_support/all'
require 'thread'
require 'celluloid'
require 'celluloid/autostart'
require 'celluloid/io'
require 'http'
require 'json'
require 'securerandom'
require 'versionomy'
Dir.glob("./config/initializers/**/*.rb") {|file| require file}
Dir.glob("./lib**/*.rb") {|file| require file}
require 'sinatra/streaming'
Stream = Sinatra::Helpers::Stream
  
module Resources
  class Home < Lattice::Resource
   
    
    def allowed_methods
      [ "GET"]
    end
    
    def encodings_provided
      { 'gzip' => :encode_gzip,
        'deflate' => :encode_deflate,
        'identity' => :encode_identity }
    end
    
    def content_types_provided
      [["image/svg+xml", :to_svg]]
    end
    
    def resource_exists?
      true
    end

  
    def params
      {
        'gem' => request.path_info[:gem],
        'version' => request.path_info[:version]
      }.merge(request.query).stringify_keys
    end
    
    def display_favicon?
      params["gem"].present? &&  params["gem"].include?("favicon")
    end
    
    def public_folder
      File.expand_path('../../../static', __FILE__)
    end
    
    def finish_request
      response.headers['Pragma'] = "no-cache"
      response.headers['Cache-Control'] = "no-cache, must-revalidate, max-age=-1"
      response.headers['Expires'] = Time.now - 1
      unless display_favicon?
        response.headers['Content-Type'] =  "image/svg+xml;  Content-Encoding: gzip; charset=utf-8; " 
      end
    end
    
    def to_svg
      if display_favicon?
        response.headers['Content-Type'] = "image/x-icon; Content-Encoding: gzip; charset=utf-8;"
        response.headers['Content-Disposition'] = "inline"
        @file = File.join(public_folder, "favicon.ico")
        open(@file, "rb") {|io| io.read }
      else 
        CelluloidManager.supervise_as :celluloid_manager if Celluloid::Actor[:celluloid_manager].blank?
          stream = Stream.new(Stream, :keep_open) { |out|
            out <<  Celluloid::Actor[:celluloid_manager].delegate(params)
          }
          stream.each {|str|  return  str }
      end
    end
    
    
  end
end

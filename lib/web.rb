$stdout.sync = true
ENV['RACK_ENV'] ||= 'development'
# !/usr/bin/env ruby
require 'rubygems'
require 'bundler'

Bundler.require :default, ENV['RACK_ENV'].to_sym

require 'sinatra/streaming'
require 'sinatra/json'
require 'json'
require 'net/http'
require 'securerandom'
require 'versionomy'
require 'active_support/core_ext/object/blank'
require 'active_support/core_ext/hash/keys'
require 'active_support/duration.rb'
require 'active_support/core_ext/time/zones.rb'

Dir.glob('./config/initializers/**/*.rb') { |file| require file }
Dir.glob('./lib**/*.rb') { |file| require file }

require_relative './request_middleware.rb' if ENV['RACK_ENV'] == 'development'

# class that is used to download shields for ruby gems using their name and version
class RubygemsDownloadShieldsApp < Sinatra::Base
  helpers Sinatra::Streaming
  register Sinatra::Async

  set :root, File.dirname(File.dirname(__FILE__)) # You must set app root
  enable :logging
  set :environments, %w(development test production webdev)
  set :environment, ENV['RACK_ENV']
  set :development, (settings.environment == 'development')
  set :raise_errors, true
  set :dump_errors, settings.development
  set :show_exceptions, settings.development

  set :static_cache_control, [:no_cache, :must_revalidate, max_age: 0]
  set :static, false # set up static file routing
  set :public_folder, File.join(settings.root, 'static') # set up the static dir (with images/js/css inside)
  set :views, File.join(settings.root, 'views') # set up the views dir

  ::Logger.class_eval do
    alias_method :write, :<<
    alias_method :puts, :<<
  end

  set :log_directory, File.join(settings.root, 'log')
  FileUtils.mkdir_p(settings.log_directory) unless File.directory?(settings.log_directory)
  set :access_log, File.open(File.join(settings.log_directory, "#{settings.environment}.log"), 'a+')
  set :access_logger, ::Logger.new(settings.access_log)
  set :logger, settings.access_logger

  configure do
    use ::Rack::CommonLogger, access_logger
  end

  before do
    content_type 'image/svg+xml;  Content-Encoding: gzip; charset=utf-8; '
    headers('Pragma' => 'no-cache')
    #    etag SecureRandom.hex
    #    last_modified(Time.now - 60)
    Time.zone = 'UTC'
    expires Time.zone.now - 1, :no_cache, :must_revalidate, max_age: 0
  end

  aget '/?:gem?/?:version?' do
    if !params[:gem].nil? && params[:gem].include?('favicon')
      send_file File.join(settings.public_folder, 'favicon.ico'), disposition: 'inline', type: 'image/x-icon'
    else
      stream :keep_open do |out|
        EM.error_handler do |error|
          puts "Error during event loop : #{error.inspect}"
          puts error.backtrace
        end
        EM.run do
          EM::HttpRequest.use RequestMiddleware if settings.development
          callback = lambda do |downloads|
            BadgeDownloader.new(params, out, downloads)
          end
          @rubygems_api = RubygemsApi.new(params, callback)
        end
      end
    end
  end
end

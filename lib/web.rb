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
require 'typhoeus'
require 'addressable/uri'

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
      em_request_badge do |out|
        RubygemsApi.new(params, badge_callback(out, {"api" => "rubygems"}))
      end
    end
  end


  # Method that fetch the badge
  #
  # @param [Sinatra::Stream] out The stream where the response is added to
  # @param [Hash] additional_params The additional params needed for the badge
  # @return [Lambda] The lambda that is used as callback to other APIS
  def badge_callback(out, additional_params = {})
    lambda do |downloads|
      original_params = CGI::parse(request.query_string)
      BadgeApi.new(params.merge(additional_params), original_params, out, downloads)
    end
  end

  # Method that fetch the badge
  #
  # @param [Block] block The block that is executed after Eventmachine starts
  # @return [void]
  def em_request_badge(&block)
    set_content_type
    stream :keep_open do |out|
      EM.error_handler do |error|
        puts "Error during event loop : #{error.inspect}"
        puts error.backtrace
      end
      EM.run do
        EM::HttpRequest.use RequestMiddleware if settings.development
        block.call(out)
      end
    end
  end

  # Method that is used to determine the proper content type based on 'extension' key from params
  # and sets the content type
  #
  # @return [void]
  def set_content_type
    if params[:extension].present?
      mime_type = Rack::Mime::MIME_TYPES[".#{params[:extension]}"]
      if mime_type.present?
        content_type "#{mime_type};  Content-Encoding: gzip; charset=utf-8; "
      else
        content_type 'image/svg+xml;  Content-Encoding: gzip; charset=utf-8; '
        params[:extension] = 'svg'
      end
    else
      content_type 'image/svg+xml;  Content-Encoding: gzip; charset=utf-8; '
    end
  end
end

# frozen_string_literal: false
$stdout.sync = true
$stderr.sync = true
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
require 'active_support/all'
require 'addressable/uri'

require 'tilt'
require 'erb'
require 'tilt/erb'
require 'prawn'

require 'forwardable'

Dir.glob('./config/initializers/**/*.rb') { |file| require file }
Dir.glob('./lib**/*.rb') { |file| require file }

require_relative '../middleware/request_middleware'
require_relative './cookie_hash'

# class that is used to download shields for ruby gems using their name and version
class RubygemsDownloadShieldsApp < Sinatra::Base
  include Helper
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
  set :request_cookies, (Thread.current[:request_cookies] ||= {})

  def self.cookie_hash(url)
    CookieHash.new.tap do |cookie_hash|
      settings.request_cookies[url].uniq.each { |cookie_data| cookie_hash.add_cookies(cookie_data) }
    end
  end

  def self.set_time_zone
    Time.zone = 'UTC'
    ENV['TZ'] = 'UTC'
  end

  ::Logger.class_eval do
    alias_method :write, :<<
    alias_method :puts, :<<
  end

  set :log_directory, File.join(settings.root, 'log')
  FileUtils.mkdir_p(settings.log_directory) unless File.directory?(settings.log_directory)
  set :access_log, File.open(File.join(settings.log_directory, "#{settings.environment}.log"), 'a+')
  set :access_logger, development ? ::Logger.new(STDOUT) : ::Logger.new(settings.access_log)
  set :logger, settings.access_logger

  configure do
    use ::Rack::CommonLogger, access_logger
  end

  before do
    headers('Pragma' => 'no-cache')
    #    etag SecureRandom.hex
    #    last_modified(Time.now - 60)
    self.class.set_time_zone
    expires Time.zone.now - 1, :no_cache, :no_store, :must_revalidate, max_age: 0
  end

  get '/favicon.*' do
    send_file File.expand_path(File.join(settings.public_folder, 'favicon.ico')), disposition: 'inline', type: 'image/x-icon'
  end

  aget '/?:gem?/?:version?' do
    settings.logger.debug("Sinatra runing in #{Thread.current}")
    em_request_badge do |out|
      RubygemsApi.new(request, params, badge_callback(out, 'api' => 'rubygems', 'request_name' => params[:gem]))
    end
  end

  # Method that fetch the badge
  #
  # @param [Sinatra::Stream] out The stream where the response is added to
  # @param [Hash] additional_params The additional params needed for the badge
  # @return [Lambda] The lambda that is used as callback to other APIS
  def badge_callback(out, additional_params = {})
    lambda do |downloads, http_response|
      BadgeApi.new(request, params.merge(additional_params), out, downloads, http_response)
    end
  end

  # Method that fetch the badge
  #
  # @param [Block] block The block that is executed after Eventmachine starts
  # @return [void]
  def em_request_badge(&block)
    use_stream do |out|
      register_em_error_handler
      run_eventmachine(out, &block)
    end
  end

  # Method that opens the stream and executes a block
  #
  # @param [Block] block The block that is executed after stream is open
  # @return [void]
  def use_stream
    content_type_string = fetch_content_type(params[:extension])
    content_type(content_type_string)
    stream :keep_open do |out|
      yield out if block_given?
    end
  end

  # Method that registers a error handler on Eventmachine
  #
  # @return [void]
  def register_em_error_handler
    EM.error_handler do |error|
      settings.logger.debug "Error during event loop : #{format_error(error)}"
    end
  end

  # Method that runs a block after eventmachine starts
  # @param [Sinatra::Stream] out The stream where the response will be appended
  # @param [Block] block The block that is executed after eventmachine starts running
  # @return [void]
  def run_eventmachine(out)
    EM.run do
      EM::HttpRequest.use RequestMiddleware
      yield out if block_given?
    end
  end
end

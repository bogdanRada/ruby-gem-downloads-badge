$stdout.sync = true
$stderr.sync = true
require 'rubygems'
require "bundler"
ENV['RACK_ENV'] = ENV['RACK_ENV'] || 'development'
Bundler.require :default, (ENV["RACK_ENV"] || "development").to_sym
require 'active_support/all'
require 'thread'
require 'concurrent'
require 'concurrent-edge'
require 'json'
require 'securerandom'
require 'versionomy'
require "net/http"
require "uri"
require 'rack'
require 'webmachine/adapters/rack'
require 'webmachine'

# Require your resources here
require_relative '../app/resources/home'

class LogListener
  def call(*args)
    handle_event(Webmachine::Events::InstrumentedEvent.new(*args))
  end
  def handle_event(event)
    request = event.payload[:request]
    resource = event.payload[:resource]
    code = event.payload[:code]
    uri = URI(request.uri)

    if request.method == "POST" && request.query['_method']
      method = request.query['_method']
    else
      method = request.method
    end

    puts "[%s] method=%s uri=%s code=%d resource=%s time=%.4f" % [
      Time.now.iso8601, method, uri.path, code, resource,
      event.duration
    ]
  end
end
Webmachine::Events.subscribe('wm.dispatch', LogListener.new)


root = File.dirname(File.dirname(__FILE__))
log_directory = File.join(root, 'log')
FileUtils.mkdir_p(log_directory) unless File.directory?(log_directory)
access_log = File.open(File.join(log_directory, "#{ENV['RACK_ENV']}.log"), 'a+')
access_logger =  ENV['RACK_ENV'] == 'development' ? ::Logger.new(STDOUT) : ::Logger.new(access_log)



MyApp = Webmachine::Application.new do |app|
  # Configure your app like this:
  app.configure do |config|
    config.ip = '0.0.0.0'
    config.port = ENV['PORT'].present? ? ENV['PORT'] : 5000
    config.adapter = :Rack
    config.adapter_options = {:AccessLog => [access_logger], :Logger => access_logger}
  end
  # OR add routes this way:
  app.routes do
    add [:gem, :version, :*], Resources::Home
    add [:gem, :*], Resources::Home
    add [], Resources::Home
  end
end

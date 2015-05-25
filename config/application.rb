require 'reel'
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
    puts "[%s] method=%s uri=%s code=%d resource=%s time=%.4f" % [
      Time.now.iso8601, request.method, request.uri.to_s, code, resource,
      event.duration
    ]
  end
end
Webmachine::Events.subscribe('wm.dispatch', LogListener.new)

MyApp = Webmachine::Application.new do |app|
  # Configure your app like this:
  app.configure do |config|
    config.ip = '0.0.0.0'
    config.port = ENV['PORT'].present? ? ENV['PORT'] : 5000
    config.adapter = :Reel
    config.adapter_options = {:AccessLog => [], :Logger => Logger.new('/dev/null')}
  end
  # OR add routes this way:
  app.routes do
    add [:gem, :version, :*], Resources::Home
    add [:gem, :*], Resources::Home
    add [], Resources::Home
  end
end

 

require 'lattice'
require "lattice/server"
require File.expand_path("../boot", __FILE__)

# Require your resources here
require 'resources/home'

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


module LatticeTest
  Application = Lattice::Application.new do |app|
    app.routes do
      add [:gem, :version, :*], Resources::Home
      add [:gem, :*], Resources::Home
      add [:*], Resources::Home
    end
    app.configure do |config|
      config.adapter = :Reel
      config.adapter_options = {:AccessLog => [], :Logger => Logger.new('/dev/null')}
    end
  end
end

Lattice.app = LatticeTest::Application

 

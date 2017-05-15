load 'lib/web.rb'
require 'moneta'
require 'rack/session/moneta'
require 'localmemcache'
require "rack-timeout"
use Rack::Timeout, service_timeout: 15, wait_timeout: 30, wait_overtime:  60, service_past_wait: true
use Rack::Session::Moneta, key: 'rack.session', domain: 'ruby-gem-downloads-badge.com', path: '/', expire_after: 2592000, store: Moneta.new(:LocalMemCache, file: 'db/session_store.db')
use Rack::Session::Moneta do
  use :Expires
  adapter :LocalMemCache
end
run RubygemsDownloadShieldsApp

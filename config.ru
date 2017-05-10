load 'lib/web.rb'
require_relative "./lib/middleware/request_pool_middleware"
require "rack-timeout"
use Rack::Timeout, service_timeout: 15, wait_timeout: 30, wait_overtime:  60, service_past_wait: true
#use RequestPoolMiddleware
run RubygemsDownloadShieldsApp

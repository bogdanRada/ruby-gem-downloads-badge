# frozen_string_literal: true
require 'etc'
$worker_processes =  Integer(ENV['WEB_CONCURRENCY'] || Etc.nprocessors)
# Sync stdout to print mesages in real time.
$stdout.sync = true
# Preload app to make it faster
preload_app true
# The worker concurrency (CPU cores)
worker_processes $worker_processes
# The timeout for each request
timeout 120
# Rainbows configuration for using Eventmachine
Rainbows! do
  use :NeverBlock, :pool_size => 128
  keepalive_timeout(100)
  worker_connections 128/$worker_processes
end

before_fork do |_server, _worker|
  Signal.trap 'TERM' do
    puts 'Unicorn master intercepting TERM and sending myself QUIT instead'
    Process.kill 'QUIT', Process.pid
  end
  if defined?(ActiveRecord::Base)
    ActiveRecord::Base.connection.disconnect!
  end
  # ...
end

after_fork do |_server, _worker|
  Signal.trap 'TERM' do
    puts 'Unicorn worker intercepting TERM and doing nothing. Wait for master to send QUIT'
  end
  # ...
end

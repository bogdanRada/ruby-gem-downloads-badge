# frozen_string_literal: true

# Sync stdout to print messages in real time.
$stdout.sync = true
# Preload app to make it faster
preload_app true
# The worker concurrency (CPU cores)
worker_processes Integer(ENV['WEB_CONCURRENCY'] || 10)
# The timeout for each request
timeout 120
# Rainbows configuration for using Eventmachine
Rainbows! do
  use :EventMachine
  keepalive_timeout(100)
end

before_fork do |_server, _worker|
  Signal.trap 'TERM' do
    puts 'Unicorn master intercepting TERM and sending myself QUIT instead'
    Process.kill 'QUIT', Process.pid
  end
  if defined?(ActiveRecord::Base)
    #noinspection RubyResolve
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

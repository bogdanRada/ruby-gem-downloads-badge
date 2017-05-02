# frozen_string_literal: true
# Sync stdout to print mesages in real time.
$stdout.sync = true
# Preload app to make it faster
preload_app true
# The worker concurrency (CPU cores)
worker_processes Integer(ENV['WEB_CONCURRENCY'] || 10)
# The timeout for each request
timeout 1260
# Rainbows configuration for using Eventmachine
Rainbows! do
  use :EventMachine
end


before_fork do |server, worker|
  Signal.trap 'TERM' do
    puts 'Unicorn master intercepting TERM and sending myself QUIT instead'
    Process.kill 'QUIT', Process.pid
  end
  if defined?(ActiveRecord::Base)
    ActiveRecord::Base.connection.disconnect!
  end
  # ...
end

after_fork do |server, worker|
  Signal.trap 'TERM' do
    puts 'Unicorn worker intercepting TERM and doing nothing. Wait for master to send QUIT'
  end
  # ...
end

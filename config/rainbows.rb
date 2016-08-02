# frozen_string_literal: true
# Sync stdout to print mesages in real time.
$stdout.sync = true
# Preload app to make it faster
preload_app true
# The worker concurrency (CPU cores)
worker_processes Integer(ENV['WEB_CONCURRENCY'] || 10)
# The timeout for each request
timeout 30
# Rainbows configuration for using Eventmachine
Rainbows! do
  use :EventMachine
end
# Replace with MongoDB or whatever
before_fork do |_server, _worker|
  # Replace with MongoDB or whatever
  if defined?(ActiveRecord::Base)
    ActiveRecord::Base.connection.disconnect!
  end
end

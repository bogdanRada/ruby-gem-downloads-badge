preload_app true
worker_processes Integer(ENV["WEB_CONCURRENCY"] || 3)

timeout 30
Rainbows! do
  use :EventMachine
end

before_fork do |server, worker|
  # Replace with MongoDB or whatever
  if defined?(ActiveRecord::Base)
    ActiveRecord::Base.connection.disconnect!
  end
end
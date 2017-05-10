# encoding: utf-8
# ThreadPoolMiddleware is a Rack Middleware which runs each request in its own
# thread
class RequestPoolMiddleware
  SIZE = 10

  def initialize(app, options = {})
    @app = app
    @pool = Concurrent::ThreadPoolExecutor.new(
      min_threads: [SIZE, Concurrent.processor_count].max,
      max_threads: [SIZE,  Concurrent.processor_count].max + SIZE,
      max_queue:  ([SIZE, Concurrent.processor_count].max + SIZE) * 100,
      fallback_policy: :caller_runs)
  end

  def call(parent_env)
    env = parent_env.dup
    future = Concurrent::Future.execute(:executor => @pool) do
     request(env)
   end.then(&:succ).value!
  end

  private

  def request(env)
    env['async.orig_callback'] = env.delete('async.callback')
    result = @app.call(env)
    env['async.orig_callback'].call result
  end

end

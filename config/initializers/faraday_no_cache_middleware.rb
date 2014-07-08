class FaradayNoCacheMiddleware   

    
  def initialize(app)
    @app = app
  end
 
  def call(env)
    @app.call(env).on_complete do
        env[:response_headers]["Cache-Control"] = 'no-cache'
        env[:response_headers]["Pragma"] = 'no-cache'
        env[:response_headers]["Expires"] = Time.now 
  end
       
  end
 
  
end


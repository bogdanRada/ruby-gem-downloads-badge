class FaradayNoCacheMiddleware   

    
  def initialize(app)
    @app = app
  end
 
  def call(env)
    @app.call(env).on_complete do
        env[:response_headers]["Cache-Control"] =  "no-cache, no-store, max-age=0, must-revalidate"
        env[:response_headers]["Pragma"] = "no-cache"
  end
       
  end
 
  
end


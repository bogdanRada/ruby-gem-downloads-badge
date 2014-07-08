class FaradayNoCacheMiddleware   

    
  
  
  def initialize(app)
    @app = app
  end
 
  def call(env)
    @app.call(env).on_complete do
      env[:response_headers].merge(custom_headers) if env.has_key?(:response_headers)
      env[:request_headers].merge(custom_headers) if env.has_key?(:request_headers)
    end
       
  end
 
  
  def custom_headers
    headers= {}
    headers["Cache-Control"] =  "no-cache, no-store, max-age=0, must-revalidate"
    headers["Pragma"] = "no-cache"
    headers
  end
  
end


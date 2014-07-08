class FaradayNoCacheMiddleware   

    
  
  
  def initialize(app)
    @app = app
  end
 
  def call(env)
    headers= {}
    headers["Cache-Control"] =  "no-cache, no-store, max-age=0, must-revalidate"
    headers["Pragma"] = "no-cache"
     
    @app.call(env).on_complete do
      env[:response_headers].merge!(headers)
    end
       
  end
 
  
  
end


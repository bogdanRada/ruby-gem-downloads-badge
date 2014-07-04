
class RubygemsApi
  
  def initialize
    @api_conn = Faraday.new "https://rubygems.org", :ssl => {:verify => false } do |con|
      con.request :url_encoded
      con.response :logger
      con.adapter :net_http
      # con.use Faraday::HttpCache, store: RedisStore
    end
  end
  
  
  def fetch_data(url)
     resp =@api_conn.get do |req|
      req.url url
      req.headers['Content-Type'] = 'application/json'
      req.options.timeout = 5           # open/read timeout in seconds
      req.options.open_timeout = 2
    end
    resp.on_complete {
      @res = resp.body 
      @res = JSON.parse(@res)
      yield @res if block_given?
      #request.env['async.callback'].call(response)
    }
  end
  

  
  
end
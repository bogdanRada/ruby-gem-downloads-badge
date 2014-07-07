
require_relative './gem_version_manager'
class RubygemsApi
  
  def initialize(manager)
    @manager = manager
    @api_conn = Faraday.new "https://rubygems.org", :ssl => {:verify => false } do |con|
      con.request :url_encoded
      con.response :logger
      con.adapter :em_http
    end
  end
  
  
  def fetch_data(url, &block)
    resp =@api_conn.get do |req|
      req.url url
      req.headers['Content-Type'] = 'application/json'
      req.options.timeout = 5           # open/read timeout in seconds
      req.options.open_timeout = 2
    end
    resp.on_complete {
      @res = resp.body 
      begin
        @res = JSON.parse(@res)
      rescue  JSON::ParserError => e
        puts e.inspect
        @manager.downloads_count = GemVersionManager::INVALID_COUNT;
      end
      block.call @res 
      #request.env['async.callback'].call(response)
    }
  end
  

  
  
end
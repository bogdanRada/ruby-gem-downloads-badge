require_relative './gem_version_manager'
class BadgeDownloader
  
  def initialize( params = {})
    @color = params[:color].nil? ? "blue" : params[:color] ;
    @style =  params[:style].nil? ? '': params[:style]; 
    @style = '?style=flat'  if @style == "flat"
    @color = "lightgrey" if @count == "invalid"
    @gem_manager  =GemVersionManager.new(params)
    @badge_conn ||=  get_faraday_shields_connection
  end
    
  def download_shield
    count = @gem_manager.fetch_gem_downloads
    count = 0 if count.nil?
    resp = @badge_conn.get do |req|
      req.url "/badge/downloads-#{count}-#{@color}.svg#{@style}"
      req.headers['Content-Type'] = "image/svg+xml; Connection: keep-alive; Content-Encoding: gzip; charset=utf-8"
      req.options.timeout = 5           # open/read timeout in seconds
      req.options.open_timeout = 2
    end
    resp.on_complete {
      return  resp.body 
    }
  end

    
  private
      
  def get_faraday_shields_connection
    Faraday.new "http://img.shields.io" do |con|
      con.request :url_encoded
      con.response :logger
      con.adapter :net_http
      #   con.use Faraday::HttpCache, store: RedisStore
    end
  end
    
end
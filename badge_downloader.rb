require_relative './gem_version_manager'
class BadgeDownloader
  
  def initialize( params = {})
    @color = params[:color].nil? ? "blue" : params[:color] ;
    @style =  params[:style].nil? ? '': params[:style]; 
    @style = '?style=flat'  if @style == "flat"
    @gem_manager  =GemVersionManager.new(params)
    @color = "lightgrey" if @gem_manager.get_count  == "invalid"
    @params = params
    @badge_conn ||=  get_faraday_shields_connection
  end
    
  def download_shield
    if @gem_manager.get_count == "invalid" || @params[:gem].nil?
        return   fetch_image_shield
    else
      @gem_manager.fetch_gem_downloads do
          fetch_image_shield
      end
    end
  end

    
  private
  
  def fetch_image_shield
    count = @gem_manager.get_count
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
      
  def get_faraday_shields_connection
    Faraday.new "http://img.shields.io" do |con|
      con.request :url_encoded
      con.response :logger
      con.adapter :net_http
      #   con.use Faraday::HttpCache, store: RedisStore
    end
  end
    
end
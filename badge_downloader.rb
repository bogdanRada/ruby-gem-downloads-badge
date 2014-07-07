require_relative './gem_version_manager'
class BadgeDownloader
  
  @attrs = [:color, :style :gem_manager, :params, :badge_conn, :output_buffer]
      
      attr_reader *@attrs
      attr_accessor *@attrs

  def initialize( params, output_buffer)
    @color = params[:color].nil? ? "blue" : params[:color] ;
    @style =  params[:style].nil? ? '': params[:style]; 
    @style = '?style=flat'  if @style == "flat"
    @gem_manager  =GemVersionManager.new(params)
    @params = params
    @badge_conn =  get_faraday_shields_connection
    @output_buffer = output_buffer
  end
  
    
  def download_shield
    if @gem_manager.invalid_count? || @gem_manager.gem_name.nil?
        return   fetch_image_shield
    else
      @gem_manager.fetch_gem_downloads do
          fetch_image_shield
      end
    end
  end

    
  private
  
  def fetch_image_shield
    count = @gem_manager.downloads_count
    @color = "lightgrey" if @gem_manager.invalid_count?
    count = 0 if count.nil?
    resp = @badge_conn.get do |req|
      req.url "/badge/downloads-#{count}-#{@color}.svg#{@style}"
      req.headers['Content-Type'] = "image/svg+xml; Connection: keep-alive; Content-Encoding: gzip; charset=utf-8"
      req.options.timeout = 5           # open/read timeout in seconds
      req.options.open_timeout = 2
    end
    resp.on_complete {
       @output_buffer <<  resp.body
       @output_buffer.close
    }
  end
      
  def get_faraday_shields_connection
    Faraday.new "http://img.shields.io" do |con|
      con.request :retry
      con.response :logger
      con.adapter :em_http
      #   con.use Faraday::HttpCache, store: RedisStore
    end
  end
    
end
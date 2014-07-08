
require_relative './rubygems_api'
class BadgeDownloader
  
  INVALID_COUNT = "invalid"
  
  @attrs = [:color, :style, :shield_conn, :downloads_count, :params, :output_buffer]
      
  attr_reader *@attrs
  attr_accessor *@attrs

  def initialize( params, output_buffer)
    @color = params[:color].nil? ? "blue" : params[:color] ;
    @style =  params[:style].nil? ? '': params[:style]; 
    @style = '?style=flat'  if @style == "flat"
    @downloads_count = nil
    @params = params
    @output_buffer = output_buffer
    @shield_conn =  get_faraday_shields_connection
  end
  

  def display_total?
    !@params[:type].nil? && @params[:type] == "total"
  end
  
  def invalid_count?
    @downloads_count == BadgeDownloader::INVALID_COUNT
  end
  
  def fetch_image_shield
    @color = "lightgrey" if invalid_count?
    @downloads_count = 0 if @downloads_count.nil?
    resp =   @shield_conn.get do |req|
      req.url "/badge/downloads-#{@downloads_count }-#{@color}.svg#{@style}"
      req.headers['Content-Type'] = "image/svg+xml; Content-Encoding: gzip; charset=utf-8;"
      req.options.timeout = 5           # open/read timeout in seconds
      req.options.open_timeout = 2
    end
    resp.on_complete {
      @output_buffer << resp.body
      @output_buffer.close
    }
  end
  
 
  private 
  
      
  def get_faraday_shields_connection
    Faraday.new "http://img.shields.io" do |con|
      con.request :url_encoded
      con.response :logger
      con.adapter :em_http
      #   con.use Faraday::HttpCache, store: RedisStore
    end
  end
    
end
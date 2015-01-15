
class BadgeDownloader
  @attrs = [:color, :style, :output_buffer, :rubygems_api]
      
  attr_reader *@attrs
  attr_accessor *@attrs

  def initialize( params, output_buffer)
    @color = params['color'].nil? ? "blue" : params[:color] ;
    @style =  params['style'].nil?  || params['style'] != 'flat' ? '': "?style=#{params['style']}"; 
    @output_buffer = output_buffer
    @rubygems_api = RubygemsApi.new(params) 
  end
  
  def fetch_image_badge_svg
    if @rubygems_api.has_errors?
      fetch_image_shield
    else
      fetch_gem_shield
    end
  end
  
  private 
  
  def fetch_gem_shield
    @rubygems_api.fetch_gem_downloads do
      fetch_image_shield
    end
  end

  
  def fetch_image_shield
    @rubygems_api.set_final_downloads_count
    @color = "lightgrey" if @rubygems_api.has_invalid_count?
    url = "http://img.shields.io/badge/downloads-#{@rubygems_api.downloads_count }-#{@color}.svg#{@style}"
    http = EventMachine::HttpRequest.new(url).get 
    http.errback { |e| puts "Error during fetching data for #{url}: #{e.inspect}" }
    http.callback {
      @output_buffer <<  http.response
      @output_buffer.close
    }
  end



 
 
    
end

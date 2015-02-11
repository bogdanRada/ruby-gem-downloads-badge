require_relative './http_fetcher'
class BadgeDownloader
  include Celluloid
  include Celluloid::Logger
  
  INVALID_COUNT = "invalid"
  API_METHODS =  [:has_errors?, :downloads_count, :fetch_downloads_data]
  
  @attrs = [:color, :style, :output_buffer, :rubygems_api]
 
  attr_accessor *@attrs

  def work( params, external_api_details, manager)
    @condition = Celluloid::Condition.new
    @color = params['color'].nil? ? "blue" : params['color'] ;
    @style =  params['style'].nil?  || params['style'] != 'flat' ? '': "?style=#{params['style']}"; 
    @display_metric = !params['metric'].nil? && (params['metric'] == "true" || params['metric']  == true )
    @api_data = external_api_details
     manager.register_worker_for_job(params, Actor.current)
end
  
  def fetch_image_badge_svg(manager_blk)
    if api_has_methods?
      if @api_data.has_errors?
        fetch_image_shield(manager_blk)
      else
        blk = lambda do |sum|
          @condition.signal(sum)
        end
        @api_data.async.fetch_downloads_data(blk) 
        wait_result = @condition.wait
        @api_data.downloads_count = wait_result
        fetch_image_shield(manager_blk)
      end
    else
      raise "The API must implement all necessary methods #{API_METHODS.join(",  ")}"
    end
  end
  
  private 
  
  def api_has_methods?
    API_METHODS & @api_data.methods == API_METHODS
  end
  
  
  def fetch_image_shield(manager_blk)
    set_final_downloads_count
    url = "https://img.shields.io/badge/downloads-#{@api_data.downloads_count }-#{@color}.svg#{@style}"
    fetcher = HttpFetcher.new
    future = fetcher.future.fetch(url)
    response = future.value(10)
    manager_blk.call response
  end
  
  def set_final_downloads_count
    if @api_data.has_errors? 
      @api_data.downloads_count = BadgeDownloader::INVALID_COUNT 
      @color = "lightgrey" 
    end
    @api_data.downloads_count = 0 if  @api_data.downloads_count.nil?
    if  @api_data.downloads_count != BadgeDownloader::INVALID_COUNT
      if @display_metric
        @api_data.downloads_count  = number_with_metric( @api_data.downloads_count)  
      else
        @api_data.downloads_count  =  number_with_delimiter( @api_data.downloads_count)
      end
    end
  end

  def  number_with_metric(number) 
    metric_prefix = ['k', 'M', 'G', 'T', 'P', 'E', 'Z', 'Y']
    metric_power = metric_prefix.map.with_index { |item, index|  (1000**(index + 1)) }
    i = metric_prefix.size - 1
    while i >= 0  do
      limit = metric_power[i]
      if (number > limit) 
        number = (number / limit).to_f.round;
        return ''+number.to_s + metric_prefix[i].to_s;
      end  
      i -= 1
    end
    return ''+number.to_s;
  end
  
  
  def number_with_delimiter(number, delimiter=",", separator=".")
    begin
      parts = number.to_s.split('.')
      parts[0].gsub!(/(\d)(?=(\d\d\d)+(?!\d))/, "\\1#{delimiter}")
      parts.join separator
    rescue
      number
    end
  end

    
end

require_relative './http_fetcher'
class BadgeDownloader
  include Celluloid
  include Celluloid::Logger
  INVALID_COUNT = "invalid"
  
  @attrs = [:manager, :params,:color, :style, :job_id, :display_metric, :api_data, :downloads_count, :output_buffer]
 
  attr_accessor *@attrs

  def work( params,manager_blk,  api_actor_name)
    @manager_blk = manager_blk
    @params = params
    @color = @params['color'].nil? ? "blue" : @params['color'] ;
    @style =  @params['style'].nil?  || params['style'] != 'flat' ? '': "?style=#{@params['style']}"; 
    @display_metric = @params['metric'].nil? && (@params['metric'] == "true" || @params['metric']  == true )
    @api_actor_name = api_actor_name
    api = Celluloid::Actor[@api_actor_name.to_s.to_sym]
    api.work(@params)
    if api. has_errors?
      fetch_image_badge_svg  BadgeDownloader::INVALID_COUNT
    else
      blk = lambda do |sum|
       fetch_image_badge_svg sum
      end
      api.future.fetch_downloads_data(blk)
    end
  end
  
  
  private
  
  def fetch_image_badge_svg(count)
    @downloads_count = count
    if     @downloads_count == BadgeDownloader::INVALID_COUNT
      @color = "lightgrey"
    end
    @downloads_count = 0 if  @downloads_count.nil?
    if  @downloads_count != BadgeDownloader::INVALID_COUNT
      if @display_metric
        @downloads_count  = number_with_metric(@downloads_count)  
      else
        @downloads_count  =  number_with_delimiter(@downloads_count)
      end
    end
    url = "https://img.shields.io/badge/downloads-#{@downloads_count }-#{@color}.svg#{@style}"
    fetcher = HttpFetcher.new
    blk = lambda do  |response|
      @manager_blk.call response
    end
    fetcher.async.fetch_async({:url => url}, blk) 
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

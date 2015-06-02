
class BadgeDownloader
  INVALID_COUNT = 'invalid'
  API_METHODS = %w(errors_exist? downloads_count fetch_downloads_data)

  attr_accessor :color, :style, :output_buffer, :rubygems_api

  def initialize(params, output_buffer, external_api_details)
    @color = params['color'].nil? ? 'blue' : params[:color]
    @style = params['style'].nil? || params['style'] != 'flat' ? '' : "?style=#{params['style']}"
    @display_metric = !params['metric'].nil? && (params['metric'] == 'true' || params['metric'] == true)
    @output_buffer = output_buffer
    @api_data = external_api_details
  end

  def fetch_image_badge_svg
    if api_has_methods?
      if @api_data.errors_exist?
        fetch_image_shield
      else
        @api_data.fetch_downloads_data do
          fetch_image_shield
        end
      end
    else
      raise "The API must implement all necessary methods #{API_METHODS}"
    end
  end

private

  def api_has_methods?
    (API_METHODS & @api_data.methods.map(&:to_s)) == API_METHODS
  end

  def fetch_image_shield
    set_final_downloads_count
    url = "http://img.shields.io/badge/downloads-#{@api_data.downloads_count }-#{@color}.svg#{@style}"
    http = EventMachine::HttpRequest.new(url).get
    http.errback { |e| puts "Error during fetching data for #{url}: #{e.inspect}" }
    http.callback do
      unless @output_buffer.closed?
      @output_buffer << http.response
      @output_buffer.close
      end
    end
  end

  def set_final_downloads_count
    if @api_data.errors_exist?
      @api_data.downloads_count = BadgeDownloader::INVALID_COUNT
      @color = 'lightgrey'
    end
    @api_data.downloads_count = 0 if @api_data.downloads_count.nil?
    return if @api_data.downloads_count == BadgeDownloader::INVALID_COUNT
    if @display_metric
      @api_data.downloads_count = number_with_metric(@api_data.downloads_count)
    else
      @api_data.downloads_count = number_with_delimiter(@api_data.downloads_count)
    end
  end

  def number_with_metric(number)
    metric_prefix = %w(k M G T P E Z Y)
    metric_power = metric_prefix.map.with_index { |_item, index| (1000**(index + 1)) }
    i = metric_prefix.size - 1
    while i >= 0
      limit = metric_power[i]
      if number > limit
        number = (number / limit).to_f.round
        return '' + number.to_s + metric_prefix[i].to_s
      end
      i -= 1
    end
    '' + number.to_s
  end

  def number_with_delimiter(number, delimiter = ',', separator = '.')
    parts = number.to_s.split('.')
    parts[0].gsub!(/(\d)(?=(\d\d\d)+(?!\d))/, "\\1#{delimiter}")
    parts.join separator
  rescue
    number
  end
end

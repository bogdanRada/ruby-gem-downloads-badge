require_relative './number_formatter.rb'
# class used to download badges from shields.io
#
# @!attribute color
#   @return [String] color used for colouring the badge
#
# @!attribute style
#   @return [String] The style of the badge (@example  'flat')
#
# @!attribute output_buffer
#   @return [Celluloid::WebSocket::Client] A websocket client that is used to chat witht the webserver
#
# @!attribute rubygems_api
#   @return [Hash] the options that can be used to connect to webser and send additional data
class BadgeDownloader
  # constant that is used to show message for invalid badge
  INVALID_COUNT = 'invalid'
  # the api methods to which the API class must respond to
  API_METHODS = %w(errors_exist? downloads_count fetch_downloads_data)
  attr_accessor :params, :output_buffer, :api_data

  def initialize(params, output_buffer, external_api_details)
    @params = params
    @output_buffer = output_buffer
    @api_data = external_api_details
  end

  def fetch_image_badge_svg
    if api_has_methods?
      @api_data.fetch_downloads_data do
        fetch_image_shield
      end
    else
      raise "The API must implement all necessary methods #{API_METHODS}"
    end
  end

  def colour
    if api_has_errors?
      'lightgrey'
    else
      @params['color'].blank? ? 'blue' : @params[:color]
    end
  end

  def api_has_errors?
    @api_data.errors_exist?
  end

  def style_param
    @params['style']
  end

  def metric_param
    @params['style']
  end

  def style_flat?
    style_param.blank? || style_param == 'flat'
  end

  def style
    style_flat? ? '' : "?style=#{style_param}"
  end

  def display_metric
    metric_param.present? && metric_param.to_s.downcase == 'true'
  end

  def api_has_methods?
    (API_METHODS & @api_data.methods.map(&:to_s)) == API_METHODS
  end

  def build_badge_url
    "http://img.shields.io/badge/downloads-#{set_final_downloads_count}-#{colour}.svg#{style}"
  end

  def fetch_image_shield
    http = EventMachine::HttpRequest.new(build_badge_url).get
    http.errback { |error| puts "Error during fetching data for #{url}: #{error.inspect}" }
    http.callback do
      print_badge(http)
    end
  end

  def print_badge(http)
    return if @output_buffer.closed?
    @output_buffer << http.response
    @output_buffer.close
  end

  def set_final_downloads_count
    api_has_errors? ? BadgeDownloader::INVALID_COUNT : format_number(@api_data.downloads_count)
  end

  def format_number(count)
    NumberFormatter.new(count, display_metric).formatted_display
  end
end

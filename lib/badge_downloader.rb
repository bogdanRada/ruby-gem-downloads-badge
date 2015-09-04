require_relative './number_formatter.rb'
require_relative './helper'
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
  include Helper
  # constant that is used to show message for invalid badge
  INVALID_COUNT = 'invalid'

  attr_reader :params, :api_data

  def initialize(params, output_buffer, external_api_details)
    @params = params
    @api_data = external_api_details
    callback = ->(downloads) { fetch_image_shield(downloads, output_buffer) }
    @api_data.fetch_downloads_data(callback)
  end

  def style_param
    @params.fetch('style', 'flat')
  end

  def metric_param
    @params.fetch('metric', false)
  end

  def style
    style_param == 'flat' ? '' : "?style=#{style_param}"
  end

  def display_metric
    metric_param.present? && metric_param.to_s.downcase == 'true'
  end

  def build_badge_url(downloads)
    colour = downloads.blank? ? 'lightgrey' : @params.fetch('color', 'blue')
    formatted_number = format_number_of_downloads(downloads)
    "http://img.shields.io/badge/downloads-#{formatted_number}-#{colour}.svg#{style}"
  end

  def fetch_image_shield(downloads, output_buffer)
    url = build_badge_url(downloads)
    fetch_data(url) do |http_response|
      print_to_output_buffer(http_response, output_buffer)
    end
  end

  def format_number_of_downloads(downloads)
    downloads.blank? ? BadgeDownloader::INVALID_COUNT : NumberFormatter.new(downloads, display_metric).formatted_display
  end
end

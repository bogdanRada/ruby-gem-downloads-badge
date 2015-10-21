require_relative './number_formatter.rb'
require_relative './helper'
# class used to download badges from shields.io
#
# @!attribute params
#   @return [Hash] THe params received from URL
#
# @!attribute api_data
#   @return [RubygemsApi] The instance of the api class that is used to download the downloads count
class BadgeDownloader
  include Helper
  # constant that is used to show message for invalid badge
  INVALID_COUNT = 'invalid'

  attr_reader :params, :api_data

  # Initializes the instance with the params from controller, and will try to download the information about the rubygems
  # and then will try to download the badge to the output stream
  # @see #fetch_image_shield
  # @see RubygemsApi#fetch_downloads_data
  #
  # @param [Hash] params describe params
  # @option params [String] :color The color of the badge
  # @option params [String]:style The style of the badge
  # @option params [Boolean] :metric This will decide if the number will be formatted using metric or delimiters
  # @param [Sinatra::Stream] output_buffer describe output_buffer
  # @param [RubygemsApi] external_api_details describe external_api_details
  # @return [void]
  def initialize(params, output_buffer, downloads)
    @params = params
    @output_buffer = output_buffer
    fetch_image_shield(downloads)
  end

  # Fetches the param style from the params , and if is not present will return by default 'flat'
  #
  # @return [String] Returns the param style from params , otherwise will return by default 'flat'
  def style_param
    @params.fetch('style', 'flat')
  end

  # Fetches the param metric from the params , and if is not present will return by default 'false'
  #
  # @return [String] Returns the param metric from params , otherwise will return by default 'false'
  def metric_param
    @params.fetch('metric', false)
  end

  # This method is used in the URL generated for fetching the shield
  # If the style is flat will not append anything to URL, because that is the default style
  # Otherwise will return the style that was requested ( if it exists)
  #
  # @return [Type] description of returned object
  def style
    style_param == 'flat' ? '' : "?style=#{style_param}"
  end

  # Method that is used to determine if the number should be formatted using metrics or delimiters
  # by checking if the metric param is true
  #
  # @return [Boolean] Returns true if the key 'metric' from params is present and is true, otherwise false
  def display_metric
    metric_param.present? && metric_param.to_s.downcase == 'true'
  end

  # Method used to build the shield URL for fetching the SVG image
  # @see #format_number_of_downloads
  # @param [Number] downloads The number of downloads that will have to be displayed
  # @return [String] The URL that will be used in fetching the SVG image from shields.io server
  def build_badge_url(downloads)
    colour = downloads.blank? ? 'lightgrey' : @params.fetch('color', 'blue')
    formatted_number = format_number_of_downloads(downloads)
    "https://img.shields.io/badge/downloads-#{formatted_number}-#{colour}.svg#{style}"
  end

  # Method that is used for building the URL for fetching the SVG Image, and actually
  # making the HTTP connection and adding the response to the stream
  # @see #build_badge_url
  # @see Helper#fetch_data
  # @see Helper#print_to_output_buffer
  #
  # @param [Number] downloads The number of downloads that will have to be displayed
  # @param [Sinatra::Stream] output_buffer describe output_buffer
  # @return [void]
  def fetch_image_shield(downloads)
    url = build_badge_url(downloads)
    fetch_data(url) do |http_response|
      print_to_output_buffer(http_response, @output_buffer)
    end
  end
  
  def register_success_callback(http, callback, &block)
    http.stream {|chunk| @output_buffer << chunk}
    http.callback do
      @output_buffer << http.response
    end
  end

  # Method that is used for formatting the number of downloads , if the number is blank, will return invalid,
  # otherwise will format the number using the configuration from params, either using metrics or delimiters
  # @see  NumberFormatter#initialize
  # @see NumberFormatter#formatted_display
  #
  # @param [Type] downloads The number of downloads that will have to be displayed
  # @return [String] If the downloads argument is blank will return invalid, otherwise will format the numbere either with metrics or delimiters
  def format_number_of_downloads(downloads)
    downloads.blank? ? BadgeDownloader::INVALID_COUNT : NumberFormatter.new(downloads, display_metric)
  end
end

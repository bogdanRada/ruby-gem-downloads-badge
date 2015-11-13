require_relative './number_formatter.rb'
require_relative './core_api'
require_relative './helper'
# class used to download badges from shields.io
#
# @!attribute params
#   @return [Hash] THe params received from URL
#
# @!attribute output_buffer
#   @return [Stream] The Sinatra Stream to which the badge will be inserted into
# @!attribute downloads
#   @return [Hash] THe downloads count that will need to be displayed on the badge
class BadgeDownloader < CoreApi
  include Helper
  # constant that is used to show message for invalid badge
  INVALID_COUNT = 'invalid'

  attr_reader :params, :output_buffer, :downloads, :hostname

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
  # @param [Number] downloads describe external_api_details
  # @return [void]
  def initialize(params, output_buffer, downloads)
    @params = params
    @output_buffer = output_buffer
    @downloads = downloads
    @hostname = "img.shields.io"
    fetch_image_shield
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

  # Method that is used to fetch the status of the badge
  #
  # @return [String] Returns the status of the badge
  def status_param
    @params.fetch('label', 'downloads').gsub("-", "_")
  end

  # Method that is used to set the image extension
  #
  # @return [String] Returns the status of the badge
  def image_extension
    @params.fetch('extension', 'svg')
  end

  # Method used to build the shield URL for fetching the SVG image
  # @see #format_number_of_downloads
  # @return [String] The URL that will be used in fetching the SVG image from shields.io server
  def build_badge_url(extension = image_extension)
    colour = @downloads.blank? ? 'lightgrey' : @params.fetch('color', 'blue')
    "https://#{@hostname}/badge/#{status_param}-#{format_number_of_downloads}-#{colour}.#{extension}#{style}"
  end

  # Method that is used for building the URL for fetching the SVG Image, and actually
  # making the HTTP connection and adding the response to the stream
  # @see #build_badge_url
  # @see Helper#fetch_data
  # @see Helper#print_to_output_buffer
  #
  # @return [void]
  def fetch_image_shield
    fetch_data(build_badge_url) do |http_response|
      print_to_output_buffer(http_response, @output_buffer)
    end
  end



  def fetch_data(urls, callback = -> {}, &block)
    urls = urls.is_a?(Array) ? urls : [urls]
    #    uri = URI(url)
    # response = Net::HTTP.get(uri)
    Typhoeus::Config.verbose = app_settings.development? ? true : false
    Typhoeus::Config.memoize = true
    hydra = Typhoeus::Hydra.new(max_concurrency: 1)
    requests = urls.map { |url|
      request = Typhoeus::Request.new(url, followlocation: true, ssl_verifypeer: false, ssl_verifyhost: 0)
      hydra.queue(request)
      request
    }
    hydra.run
    responses = requests.map { |request|
      request.response.body
    }
    res = callback_before_success(responses)
    dispatch_http_response(res.first, callback, &block)
  end


  # Method that is used for formatting the number of downloads , if the number is blank, will return invalid,
  # otherwise will format the number using the configuration from params, either using metrics or delimiters
  # @see  NumberFormatter#initialize
  # @see NumberFormatter#formatted_display
  #
  # @return [String] If the downloads argument is blank will return invalid, otherwise will format the numbere either with metrics or delimiters
  def format_number_of_downloads
    @downloads.blank? ? BadgeDownloader::INVALID_COUNT : NumberFormatter.new(@downloads, display_metric)
  end
end

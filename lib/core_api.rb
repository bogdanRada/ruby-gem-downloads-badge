# frozen_string_literal: true
require_relative './helper'
# module that is used for formatting numbers using metrics
#
# @!attribute params
#   @return [Hash] THe params received from URL
# @!attribute hostname
#   @return [String] THe hostname from where the badges are fetched from
# @!attribute base_url
#   @return [String] THe base_url of the API
class CoreApi
  include Helper


  attr_reader :params

  # Returns the connection options used for connecting to API's
  #
  # @return [Hash] Returns the connection options used for connecting to API's
  def em_connection_options(url = nil)
    {
      connect_timeout: 30, # default connection setup timeout
      inactivity_timeout: 60, # default connection inactivity (post-setup) timeout
      ssl: {
        cipher_list: 'ALL',
        verify_peer: false,
        ssl_version: 'TLSv1',
        sni_hostname: parsed_url_property(url)
      },
      head: {
        'ACCEPT' => '*/*',
        'Connection' => 'keep-alive'
      }
    }
  end

  # Returns the request options used for connecting to API's
  #
  # @return [Hash] Returns the request options used for connecting to API's
  def em_request_options(data = {})
    {
      redirects: 5,              # follow 3XX redirects up to depth 5
      keepalive: true,           # enable keep-alive (don't send Connection:close header)
      head: (data[:head] || {}).merge(
        'ACCEPT' => '*/*',
        'Connection' => 'keep-alive'
      ),
      body: (params[:body] || {})
    }
  end

  # instantiates an eventmachine http request object that will be used to make the htpp request
  # @see EventMachine::HttpRequest#initialize
  #
  # @param [String] url The URL that will be used in the HTTP request
  # @return [EventMachine::HttpRequest] Returns an http request object
  def em_request(request_url, options)
    em_request = EventMachine::HttpRequest.new(request_url, em_connection_options(request_url))
    em_request.send(options.fetch('http_method', 'get'), em_request_options(options))
  end

  def setup_request_cookies_for_url
    request_cookies[@base_url] ||= []
  end

  def persist_cookies_for_url(cookie_string)
    return if cookie_string.blank?
    setup_request_cookies_for_url
    request_cookies[@base_url] << cookie_string
  end

  def persist_cookies(http_client)
    http_client.headers do |head|
      cookie_string = head[EM::HttpClient::SET_COOKIE]
      persist_cookies_for_url(cookie_string)
    end
  end

  def options_base_url(options, request_url)
    request_name = options['request_name']
    request_name.present? ? request_name : request_url
  end

  def get_cookie_string_for_base_url(base_url)
    cookie_h = request_cookies[base_url].present? ? cookie_hash(base_url) : {}
    return if cookie_h.blank?
    get_string_from_cookie_data(cookie_h)
  end

  def get_string_from_cookie_data(cookie_h)
    cookie_h.to_cookie_string if cookie_h.expire_time >= Time.zone.now
  end

  def add_cookie_header(options, url)
    set_time_zone
    @base_url = options_base_url(options, url)
    cookie_string = get_cookie_string_for_base_url(@base_url)
    options['head']['cookie'] = cookie_string if cookie_string.present?
  end

  def request_coming_from_repo?
    defined?(@request) && @request.env['HTTP_REFERER'].to_s.include?('https://github.com/bogdanRada/ruby-gem-downloads-badge')
  end

  def request_allowed_for_customized_badge?
    ((env_production? && request_coming_from_repo?) || !env_production?)
  end

  def setup_options_for_url(options, request_url)
    options['head'] ||= {}
    options['url_fetched'] = request_url
  end

  # Method that fetch the data from a URL and registers the error and success callback to the HTTP object
  # @see #fetch_real_data
  # @see #callback_error
  #
  # @param [url] url The URL that is used to fetch data from
  # @param [Lambda] callback The callback that will be called if the response is blank
  # @param [Proc] block If the response is not blank, the block will receive the response
  # @return [void]
  def fetch_data(url, options = {}, &block)
    options = options.stringify_keys
    setup_options_for_url(options, url)
    fetch_real_data(url, options, &block)
  end

  # Method that fetch the data from a URL and registers the error and success callback to the HTTP object
  # @see #em_request
  # @see #register_error_callback
  # @see #register_success_callback
  #
  # @param [url] url The URL that is used to fetch data from
  # @param [Lambda] callback The callback that will be called if the response is blank
  # @param [Proc] block If the response is not blank, the block will receive the response
  # @return [void]
  def fetch_real_data(url, options = {}, &block)
    add_cookie_header(options, url)
    http = em_request(url, options)
    do_fetch_real_data(http, options, &block)
  end

  def do_fetch_real_data(http_client, options, &block)
    persist_cookies(http_client)
    register_error_callback(http_client, options)
    register_success_callback(http_client, options, &block)
  end

  # Method that is used to register a success callback to a http object
  # @see #callback_before_success
  # @see #dispatch_http_response
  #
  # @param [EventMachine::HttpRequest] http The HTTP object that will be used for registering the success callback
  # @param [Lambda] callback The callback that will be called if the response is blank
  # @param [Proc] block If the response is not blank, the block will receive the response
  # @return [void]
  def register_success_callback(http, options, &block)
    http.callback do
      handle_http_callback(http, options, &block)
    end
  end

  def handle_http_callback(http, options, &block)
    http_response = http.response
    res = callback_before_success(http_response)
    dispatch_http_response(res, options, &block)
  end

  # Callback that is used before returning the response the the instance
  #
  # @param [String] response The response that will be dispatched to the instance class that made the request
  # @return [String] Returns the response
  def callback_before_success(response)
    response
  end

  # This method is used to reqister a error callback to a HTTP request object
  # @see #callback_error
  # @param [EventMachine::HttpRequest] http The HTTP object that will be used for reqisteringt the error callback
  # @return [void]
  def register_error_callback(http, options)
    http.errback { |error| callback_error(error, options) }
  end

  # Method that is used to react when an error happens in a HTTP request
  # and prints out an error message
  #
  # @param [Object] error The error that was raised by the HTTP request
  # @return [void]
  def callback_error(error, options = {})
    debug = "#{error.inspect} with #{options.inspect}"
    logger.debug("Error during fetching data  : #{debug}")
  end
end

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

  # @return [Hash] The params that Sinatra received
  attr_reader :params

  # Returns the connection options used for connecting to API's
  # @param [String] url  The url that will be used for connection, this is needed so that we can set properly the SNI hostname
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
  # @param [Hash] data The optional data that will be used to inject additional headers to the request or providing a body to the request
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
  # @param [String] request_url The URL that will be used in the HTTP request
  # @param [Hash] options The options specific to this request which are needed for setting the SNI hostname and additional headers to the request
  #
  # @return [EventMachine::HttpRequest] Returns an http request object that will be used to set the success callbacks and error callbacks
  def em_request(request_url, options)
    em_request = EventMachine::HttpRequest.new(request_url, em_connection_options(request_url))
    em_request.send(options.fetch('http_method', 'get'), em_request_options(options))
  end

  # sets the request coookies for a URL to a empty Array if was not yet instantiated already
  # @see RubygemsDownloadShieldsApp#request_cookies
  #
  # @return [void]
  def setup_request_cookies_for_url
    request_cookies[@base_url] ||= []
  end

  # sets the full cookie string received from the response to the application's request cookies store
  # so that it can be used later when a new request cames for same URL
  #
  # This is in particular used for CloudFlare to be able to send the _cfuid cookie next time a new
  # request cames for same gem, This cookie is used to prevent CloudFlare to generate new cookies for same
  # visitor, and to bypass the cache miss functionality that is executed when it can't identify the visitor
  # and use instead the caching functionality as long as is not expired
  #
  # Otherwise it could happen that CloudFlare could block the new request due to its throttling capabilities
  # and due to his security checks. This prevents this to happen by making sure that CloudFlare could always identify
  # visitors , except for the first time requests.
  #
  # Currently only Shields.io uses CLoudFlare Nginx
  #
  # @see #setup_request_cookies_for_url
  # @see RubygemsDownloadShieldsApp#request_cookies
  #
  # @param [String] cookie_string The cookie String that will be persisted for the current URL that is used.
  #
  # @return [void]
  def persist_cookies_for_url(cookie_string)
    return if cookie_string.blank?
    setup_request_cookies_for_url
    request_cookies[@base_url] << cookie_string
  end

  # persist the cookies through requests
  # @see #persist_cookies_for_url
  # @see EM::HttpClient::SET_COOKIE
  #
  # @param [EventMachine::HttpRequest] http_client The http client that will be used to retrieve the headers as soon as they are returned and start persisting them
  #
  # @return [void]
  def persist_cookies(http_client)
    http_client.headers do |head|
      cookie_string = head[EM::HttpClient::SET_COOKIE]
      persist_cookies_for_url(cookie_string)
    end
  end

  # returns the request name used for persisting cookies,
  # by checking the options received or falling back to the URL received
  #
  # @param [Hash] options The options that will be used to retrive the request_name ( for shield.io we are only interested in the gem name )
  # @param [String] request_url The URL that is used to fetch data from ( used as fallback if the options don't contain a request_name key)
  #
  # @return [String] returns the request name either from the options or it returns the request_url if a request name is not provided
  def options_base_url(options, request_url)
    request_name = options['request_name']
    request_name.present? ? request_name : request_url
  end

  # check if a cookie data already exist in the cookie store for the specified URL and if it is will return only the cookie value
  # without the other data, like expiration date, or other values that are specific to cookies
  #
  # @see RubygemsDownloadShieldsApp#request_cookies
  # @see RubygemsDownloadShieldsApp#cookie_hash
  # @see #get_string_from_cookie_data
  #
  # @param [String] base_url The URL that will be checked if exists in the cookie store of the application
  #
  # @return [String, nil] Returns the cookie value for the specified URL if exists in the cookie store and is not expired, or nil
  def get_cookie_string_for_base_url(base_url)
    cookie_h = request_cookies[base_url].present? ? cookie_hash(base_url) : {}
    return if cookie_h.blank?
    get_string_from_cookie_data(cookie_h)
  end

  # checks if a CookieHash instance is not expired and returns the cookie value , otherwise nil
  #
  # @see CookieHash#to_cookie_string
  # @see CookieHash#expire_time
  #
  # @param [CookieHash] cookie_h The CookieHash instance that will be verified if not expired
  #
  # @return [String, nil] Returns the cookie value from the Cookie data if is not expired, or nil otherwise
  def get_string_from_cookie_data(cookie_h)
    cookie_h.to_cookie_string if cookie_h.expire_time >= Time.zone.now
  end

  # Adds in the options received , inside the head key the cookie key with value of the cookie that
  # was persisted for the specified URL, if it exists
  #
  # @see #options_base_url
  # @see #get_cookie_string_for_base_url
  #
  # @param [Hash] options The options used for fetching the request name
  # @param [String] url The URL that is being used currently to fetch data from
  #
  # @return [void]
  def add_cookie_header(options, url)
    set_time_zone
    @base_url = options_base_url(options, url)
    cookie_string = get_cookie_string_for_base_url(@base_url)
    options['head']['cookie'] = cookie_string if cookie_string.present?
  end

  # INitializes the head key in the options received with a empty hash if not instantiated already
  # and sets the url fetched to the url received
  #
  # @param [Hash] options The options used for settning the head key ( needed for setting the connection options)
  # @param [String] request_url The URL that is being used currently to fetch data from
  #
  # @return [void]
  def setup_options_for_url(options, request_url)
    options['head'] ||= {}
    options['url_fetched'] = request_url
  end

  # Method that fetch the data from a URL and registers the error and success callback to the HTTP object
  # @see #setup_options_for_url
  # @see #fetch_real_data
  #
  # @param [url] url The URL that is used to fetch data from
  # @param [Hash] options The additional options needed for further processing
  # @param [Proc] block the callback that will be called when success
  # @return [void]
  def fetch_data(url, options = {}, &block)
    options = options.stringify_keys
    setup_options_for_url(options, url)
    fetch_real_data(url, options, &block)
  end

  # Method that is used to add the cookie header to the request, instantiate the Request instance and
  # register the callbacks
  # @see #add_cookie_header
  # @see #em_request
  # @see #do_fetch_real_data
  #
  # @param [url] url The URL that is used to fetch data from
  # @param [Hash] options The additional options needed for further processing
  # @param [Proc] block the callback that will be called when success
  # @return [void]
  def fetch_real_data(url, options = {}, &block)
    add_cookie_header(options, url)
    http = em_request(url, options)
    do_fetch_real_data(http, options, &block)
  end

  # Method that is used to reqister the callbacks for success, erorr, and on receiving headers
  # @see #persist_cookies
  # @see #register_error_callback
  # @see #register_success_callback
  #
  # @param [EventMachine::HttpRequest] http_client The http client used for fetching data
  # @param [Hash] options The additional options needed for further processing
  # @param [Proc] block the callback that will be called when success
  # @return [void]
  def do_fetch_real_data(http_client, options, &block)
    persist_cookies(http_client)
    register_error_callback(http_client, options)
    register_success_callback(http_client, options, &block)
  end

  # Method that is used to register a success callback to a http object
  # @see #handle_http_callback
  #
  # @param [EventMachine::HttpRequest] http The HTTP object that will be used for registering the success callback
  # @param [Hash] options The additional options needed for further processing
  # @param [Proc] block If the response is not blank, the block will receive the response
  # @return [void]
  def register_success_callback(http, options, &block)
    http.callback do
      handle_http_callback(http, options, &block)
    end
  end

  # Method that is call an additional callback before calling the success callback for parsing response
  # and dispatch the http response to the appropiate callback
  # @see #callback_before_success
  # @see #dispatch_http_response
  #
  # @param [EventMachine::HttpRequest] http The HTTP object that will be used for registering the success callback
  # @param [Hash] options The additional options needed for further processing
  # @param [Proc] block If the response is not blank, the block will receive the response
  # @return [void]
  def handle_http_callback(http, options, &block)
    http_response = http.response
    res = callback_before_success(http_response)
    dispatch_http_response(res, options, &block)
  end

  # Callback that is used before returning the response the the instance, by default it does no additional processing
  #
  # if needed this can be overriden by child classes to provide the format processing
  # before calling the dispatch_http_response method
  #
  # @param [String] response The response that will be dispatched to the instance class that made the request
  # @return [String] Returns the response
  def callback_before_success(response)
    response
  end

  # This method is used to reqister a error callback to a HTTP request object
  # @see #callback_error
  # @param [EventMachine::HttpRequest] http The HTTP object that will be used for reqisteringt the error callback
  # @param [Hash] options The additional options needed for further processing
  # @return [void]
  def register_error_callback(http, options)
    http.errback { |error| callback_error(error, options) }
  end

  # Method that is used to react when an error happens in a HTTP request
  # and prints out an error message
  #
  # @param [Object] error The error that was raised by the HTTP request
  # @param [Hash] options The additional options needed for further processing
  # @return [void]
  def callback_error(error, options = {})
    debug = "#{error.inspect} with #{options.inspect}"
    logger.debug("Error during fetching data  : #{debug}")
  end
end

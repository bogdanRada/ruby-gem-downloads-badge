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
  def em_connection_options
    {
      connect_timeout: 30,        # default connection setup timeout
      inactivity_timeout: 60,    # default connection inactivity (post-setup) timeout
      ssl: {
        cipher_list: 'ALL',
        verify_peer: false,
        ssl_version: 'TLSv1'
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
  def em_request_options(options = {})
    {
      redirects: 5,              # follow 3XX redirects up to depth 5
      keepalive: true,           # enable keep-alive (don't send Connection:close header)
      head: (options[:head] || {}).merge(
      'ACCEPT' => '*/*'
      )
    }
  end

  # instantiates an eventmachine http request object that will be used to make the htpp request
  # @see EventMachine::HttpRequest#initialize
  #
  # @param [String] url The URL that will be used in the HTTP request
  # @return [EventMachine::HttpRequest] Returns an http request object
  def em_request(url, options)
    uri = Addressable::URI.parse(url)
    conn_options = em_connection_options.merge(ssl: { sni_hostname: uri.host })
    em_request = EventMachine::HttpRequest.new(url, conn_options)
    em_request.send(options.fetch('http_method', 'get'), em_request_options(options))
  end

  def persist_cookies(http, url)
    http.headers { |head|
      cookie_string =  head[EM::HttpClient::SET_COOKIE]
      if cookie_string.present?
        request_cookies[url] ||= []
        request_cookies[url] << cookie_string
      end
    }
  end

  def add_cookie_header(options, url)
    set_time_zone
    options[:head] ||= {}
    base_url = options['request_name'].present? ? options['request_name'] : url
    cookie_h = request_cookies[base_url].present? ? cookie_hash(base_url) : {}
    options[:head]['cookie'] = cookie_h.to_cookie_string if cookie_h.present? && cookie_h.expire_time >= Time.zone.now
    base_url
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
    if options['test_default_template'].to_s == 'true'
      callback_error(url , options)
    else
      fetch_real_data(url, options, &block)
    end
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
    options = options.stringify_keys
    base_url = add_cookie_header(options, url)
    http = em_request(url, options)
    persist_cookies(http, base_url)
    register_error_callback(http, options)
    register_success_callback(http, options, &block)
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
    if http.is_a?(EM::HttpClient) && !http.response_header[EM::HttpClient::CONTENT_TYPE].include?('text/html') && http.response_header.http_status = 200 && http.response.present?
      res = callback_before_success(http.response)
      dispatch_http_response(res, options, &block)
    else
      callback_error(http.response, options.merge!('detected_http_error' => true))
    end
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
    if options['detected_http_error']
      logger.debug "Detected HTTP Connection Error for: #{error.inspect} and #{options.inspect}"
    elsif options['test_default_template']
      logger.debug "Using the customized template for: #{error.inspect} and #{options.inspect}"
    else
      logger.debug "Error during fetching data  : #{error.inspect} with #{options.inspect}"
    end
  end
end

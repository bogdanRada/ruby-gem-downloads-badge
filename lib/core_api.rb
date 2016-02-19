require_relative './helper'
require_relative './methodic_actor'
# module that is used for formatting numbers using metrics
#
# @!attribute params
#   @return [Hash] THe params received from URL
# @!attribute hostname
#   @return [String] THe hostname from where the badges are fetched from
# @!attribute base_url
#   @return [String] THe base_url of the API
module CoreApi
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

  def persist_cookies(head, url)
    cookie_string =  head["Set-Cookie"]
    return unless cookie_string.present?
    request_cookies[url] ||= []
    request_cookies[url] << cookie_string
  end

  def add_cookie_header(options, url)
    set_time_zone
    options[:head] ||= {}
    base_url = options.fetch('request_name', url) || url
    cookie_h = request_cookies[base_url].present? ? cookie_hash(base_url) : {}
    options[:head]['cookie'] = cookie_h.to_cookie_string if cookie_h.present? && cookie_h.expire_time >= Time.zone.now
    base_url
  end

  def fetch_data(url, options = {}, &block)
    options = options.stringify_keys
    base_url = add_cookie_header(options, url)
    uri = Addressable::URI.parse(url)
    conn_options = em_connection_options.merge(ssl: { sni_hostname: uri.host })
    Typhoeus::Config.verbose = false
    request = Typhoeus::Request.new(url, followlocation: true, ssl_verifypeer: false, ssl_verifyhost: 0, headers: em_request_options(options )[:head])
    request.on_headers do |response|
      if response.code != 200
        res = callback_before_success(nil)
      dispatch_http_response(res, options, &block)
      else
        persist_cookies(response.headers, base_url)
      end
    end
    request.on_body do |chunk|

      res = callback_before_success(chunk)
      dispatch_http_response(res, options, &block)
    end
    request.on_complete do |response|
      on_complete(response)
    end
    request.run
  end

  # Callback that is used before returning the response the the instance
  #
  # @param [String] response The response that will be dispatched to the instance class that made the request
  # @return [String] Returns the response
  def callback_before_success(response)
    response
  end

end

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

  # Returns the request options used for connecting to API's
  #
  # @return [Hash] Returns the request options used for connecting to API's
  def em_request_options(options = {})
    {
      head: (options[:head] || {}).merge(
      'ACCEPT' => '*/*',
      'Connection' => 'keep-alive'
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
    uri = URI(url)
    http = Net::HTTP.new(uri.host, uri.port)
    http.use_ssl = true
    http.verify_mode = OpenSSL::SSL::VERIFY_NONE # read into this
    http.set_debug_output($stdout)
    request = Net::HTTP::Get.new(uri.request_uri)
    em_request_options(options )[:head].each do |key, value|
      request[key] = value
    end
    response = http.request(request)
    persist_cookies(response.instance_variable_get("@header"), base_url)
    res = callback_before_success(response.body)
    value = dispatch_http_response(res, options, &block)
    return value
  end



  # Callback that is used before returning the response the the instance
  #
  # @param [String] response The response that will be dispatched to the instance class that made the request
  # @return [String] Returns the response
  def callback_before_success(response)
    response
  end

end

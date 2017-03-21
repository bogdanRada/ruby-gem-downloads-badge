# frozen_string_literal: true
# module that is used for formatting numbers using metrics
module Helper
# function that makes the methods incapsulated as utility functions
module_function

  delegate :settings, :cookie_hash, :set_time_zone, to: :RubygemsDownloadShieldsApp
  delegate :logger, :request_cookies, to: :settings

  # Method used for parsing a URL and fetching a specific property of the URL
  # (By default , the 'host' property)
  # @see Addressable::URI#parse
  #
  # @param [String] url  The URL that will be parsed
  # @param [String] property The property of the URL that we want to get (Default: 'host')
  #
  # @return [String,nil] The property value or nil if there is a exception in parsing the URL or the property does not exist
  def parsed_url_property(url, property = 'host')
    return if url.blank? || !url.is_a?(String)
    uri = Addressable::URI.parse(url)
    uri.present? && property.present? ? uri.send(property) : uri
  rescue
    nil
  end

  # Method used to determine the root of the application,
  # that might be helpful when trying to construct file paths relative to this value
  #
  # @return [String]
  def root
    File.expand_path(File.dirname(__dir__))
  end

  # Method used to determine if application is running in production environment
  # by checking ENV['RACK_ENV']
  #
  # @return [Boolean] Returns true if RACK_ENV is equal to production, otherwise false
  def env_production?
    ENV['RACK_ENV'] == 'production' || ENV['APP_ENV'] == "production"
  end

  # Method used to determine if a object is a valid HTTP client and has a response
  # @see #non_empty_http_response
  #
  # @param [EventMachine::HttpRequest] http The http client that will be verified for response
  #
  # @return [Boolean] Returns true if valid, otherwise false
  def valid_http_response?(http)
    http.is_a?(EM::HttpClient) && non_empty_http_response?(http)
  end

  # Method used to determine if the reponse form the http client is valid
  #
  # @param [EventMachine::HttpRequest] http The http client that will be verified for response
  #
  # @return [Boolean] Returns true if valid, otherwise false
  def non_empty_http_response?(http)
    http.response.present?
  end

  # Method used to determine if URL is from Rubygems and if has valid status code ( 200 or 404)
  # 404 are considered valid, because it determines if a gem exists or not.
  #
  # We don't check the content type for this, becasue if JSON is not returned,
  # the JSON parsing will return nil , because the parsed exception is rescued,
  # and will call the success callback with nil value, which will still show a badge
  # that is 'invalid' ( this happens also for 404 statuses, since we receive HTML format,
  # but we can still display a badge, letting people know that either there is a problem
  # with the service itself, or the requested gem does not exist )
  #
  # @see #http_valid_status_code?
  #
  # @param [EventMachine::HttpRequest] http The http client that will be verified for response
  # @param [String] url The URL that was used by the client to make the request
  #
  # @return [Boolean] Returns true if valid, otherwise false
  def rubygems_valid_response?(http, url)
    url.include?(RubygemsApi::BASE_URL) && http_valid_status_code?(http, [200, 404])
  end

  # Method used to determine if URL is from Shields.io and if has valid status code ( 200)
  # and if the content type returned is valid ( in some cases we can receive 200 status code but with invalid
  # status code, e.q. when shields.io is down or under maintenance )
  #
  # @see #http_valid_status_code?
  # @see #http_valid_content_types?
  #
  # @param [EventMachine::HttpRequest] http The http client that will be verified for response
  # @param [String] url The URL that was used by the client to make the request
  #
  # @return [Boolean] Returns true if valid, otherwise false
  def shields_io_valid_response?(http, url)
    url.include?(BadgeApi::BASE_URL) && http_valid_status_code?(http, 200) && http_valid_content_types?(http)
  end

  # Method used to detect bad responses from services, used by the middleware to log invalid responses
  # in production.
  #
  # @see #rubygems_valid_response?
  # @see #shields_io_valid_response?
  #
  # @param [EventMachine::HttpRequest] http The http client that will be verified for response
  # @param [String] url The URL that was used by the client to make the request
  #
  # @return [Boolean] Returns true if valid, otherwise false
  def valid_http_code_returned?(http_client, url)
    rubygems_valid_response?(http_client, url) || shields_io_valid_response?(http_client, url)
  end

  # Method used to check if the content type returned by the http client is not included in the list
  # of invalid content types (e.g. text/html )
  #
  # @param [EventMachine::HttpRequest] http The http client that will be verified for content type
  # @param [Array<String>] content_types The content types that are considered invalid ( e.g. text/html )
  #
  # @return [Boolean] Returns true if valid, otherwise false
  def http_valid_content_types?(http, content_types = ['text/html'])
    content_types = content_types.is_a?(Array) ? content_types : [content_types]
    !content_types.include?(http.response_header[EM::HttpClient::CONTENT_TYPE])
  end

  # Method used to check if the status code returned by http client is in the list of valid status codes
  #
  # @param [EventMachine::HttpRequest] http The http client that will be verified for status code
  # @param [Array<String>] status_codes The status codes that are considered valid ( e.g 200 )
  #
  # @return [Boolean] Returns true if valid, otherwise false
  def http_valid_status_code?(http, status_codes = [200])
    status_codes = status_codes.is_a?(Array) ? status_codes : [status_codes]
    status_codes.include?(http.response_header.http_status)
  end

  # Method used to format a exception for displaying (usually used for logging only)
  #
  # @param [Exception] error The error that will be formatted
  #
  # @return [String] Returns the formatted exception that will be used in further processing
  def format_error(error)
    "#{error.inspect} \n #{error.backtrace}"
  end

  # Returns the display_type from the params , otherwise nil
  #
  # @return [String, nil] Returns the display_type  from the params , otherwise nil
  def display_type
    @params.fetch('type', nil)
  end

  # Returns the corect mime type for the given extension ( suported extension are SVG, PNG, JPG, JPEG)
  # @param [String] extension The extension that will be used to determine the coorect MimeType that needs to be set before the response is outputted (Default: 'svg')
  #
  # @return [String] Returns the mime type that the browser will use in order to know what output to expect
  def fetch_content_type(extension = 'svg')
    extension = extension.present? && available_extension?(extension) ? extension : 'svg'
    mime_type = Rack::Mime::MIME_TYPES[".#{extension}"]
    "#{mime_type};Content-Encoding: gzip; charset=utf-8"
  end

  # Checks if a extension is currently supported by the application, by checking if it is in the list of supported extension
  #
  # @param [String] extension The extension that will be used
  #
  # @return [Boolean] Returns true if valid, otherwise false
  def available_extension?(extension)
    %w(png svg json jpg jpeg).include?(extension)
  end

  # Sanitizes a string, by replacing unsafe characters with other characters
  # Returns nil if string is blank
  #
  # @param [String] label The string that will be used
  #
  # @return [String,nil] Returns the sanitized string, or nil if string is blank
  def clean_image_label(label)
    return if label.blank?
    label.gsub(/[\s]+/, ' ').gsub(/[\_\-]+/, '_')
  end

  # Returns utf8 encoding of the msg
  # @param [String] msg
  # @return [String] ReturnsReturns utf8 encoding of the msg
  def force_utf8_encoding(msg)
    msg.respond_to?(:force_encoding) && msg.encoding.name != 'UTF-8' ? msg.force_encoding('UTF-8') : msg
  rescue
    nil
  end

  # Method that checks if we need to display the total downloads
  #
  # @return [Boolean] Returns true if we need to display the total downloads
  def display_total
    display_type.present? && display_type == 'total'
  end

  # The prefixes that can be used in metric display
  #
  # @return [Array<String>] Returns the metric prefixes array that can be used in metric display
  def metric_prefixes
    %w(k M G T P E Z Y)
  end

  # Dispatches the response either to the final callback or to the block that will use the response
  # and then call the callback
  #
  # @param [String] res The response string that will be dispatched
  # @param [Hash] options The callback that is used to dispatch further the response
  # @return [void]
  def dispatch_http_response(res, options)
    callback = options.fetch('callback', nil)
    res.blank? && callback.present? ? callback.call(res, nil) : yield(res)
  end

  # Returns the metric powers of all metric prefixes . This method is used in metric display of numbers
  # @see #metric_prefixes
  # @return [Array<Number>] An array of metric powers that correspont to each metric prefix
  def metric_power
    metric_prefixes.map.with_index { |_item, index| (1000**(index + 1)).to_i }
  end

  # Method that is used to parse a string as JSON , if it fails will return nil
  # @see JSON#parse
  # @param [string] res The string that will be parsed as JSON
  # @return [Hash, nil] Returns Hash object if the json parse succeeds or nil otherwise
  def parse_json(res)
    return if res.blank?
    JSON.parse(res)
  rescue JSON::ParserError
    nil
  end

  # Method that is used to print to a stream . If the stream is already closed will return nil
  # otherwise will append the response to the stream and close the stream
  #
  # @param [String] response THe string that will be appended to the stream
  # @param [Sinatra::Stream] output_buffer The sinatra stream that will be used to append information
  # @return [nil] The method will return nil even if is success or not, the only thing that is affected is the stream
  def print_to_output_buffer(response, output_buffer)
    return if output_buffer.closed?
    output_buffer << response
    output_buffer.close
  end

  # Method that tries to check if the version provided is a valid versin sintactical and semantical.
  # it does not check if the gem actually has that version published or not.
  # if the parsing of the version fails will return nil, otherwise will return the parsed version
  # @see Versionomy#parse
  # @param [String] gem_version The string that represents the gem version that we want to check
  # @return [String, nil] Returns nil if the version is blank or 'stable' or the parsing has failed, otherwise will return the parsed version
  def parse_gem_version(gem_version)
    return if gem_version.blank? || gem_version == 'stable'
    Versionomy.parse(gem_version)
  rescue Versionomy::Errors::ParseError
    return nil
  end

  # Given an aray of gem versions , will filter them and return only the stable versions
  #
  # @param [Array<Hash>] http_response The HTTP response as a array of Hash
  # @return [Array<Hash>] Will return only the items from the array that have the key 'prerelease' with value false
  def stable_gem_versions(http_response)
    http_response.blank? ? [] : http_response.select { |val| val['prerelease'] == false }
  end

  # method that will return nil if the array of versions is empty or will return the versions sorted
  #
  # @param [Array<Hash>] versions The versions that have to be sorted
  # @return [Array<String>] Will return nil if the array is blank or will return an array with only the version numbers sorted
  def sorted_versions(versions)
    versions.blank? ? [] : versions.map { |val| val['number'] }.version_sort
  end

  # Method to search for a version number in all gem versions and return the hash object
  #
  # @param [Array<Hash>] versions The array of gem versions that we will use for searching
  # @param [string] number The version number used for searching
  # @return [Hash] Returns the version object that has the number specified
  def find_version(versions, number)
    number.blank? ? {} : versions.find { |val| val['number'] == number }
  end

  # Method that is used to return the last item from an array of strings.
  # Will return empty string if array is blank
  #
  # @param [Array<String>] sorted_versions describe sorted_versions
  # @return [string] description of returned object
  def last_version(sorted_versions)
    sorted_versions.blank? ? '' : sorted_versions.last
  end

  # Method that is used to filter the versions, sort them and find the latest stable version
  # @see #stable_gem_versions
  # @see #sorted_versions
  # @see #last_version
  # @see #find_version
  #
  # @param [Array<Hash>] http_response The array with all the versions of the gem
  # @return [Hash] Returns the latest stable version
  def get_latest_stable_version_details(http_response)
    versions = stable_gem_versions(http_response)
    sorted_versions = sorted_versions(versions)
    last_version_number = last_version(sorted_versions)
    find_version(versions, last_version_number)
  end
end

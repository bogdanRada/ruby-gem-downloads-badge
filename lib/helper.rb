# module that is used for formatting numbers using metrics
module Helper
# function that makes the methods incapsulated as utility functions

module_function

  # The prefixes that can be used in metric display
  #
  # @return [Array<String>] Returns the metric prefixes array that can be used in metric display
  def metric_prefixes
    %w(k M G T P E Z Y)
  end

  # Returns the metric powers of all metric prefixes . This method is used in metric display of numbers
  # @see #metric_prefixes
  # @return [Array<Number>] An array of metric powers that correspont to each metric prefix
  def metric_power
    metric_prefixes.map.with_index { |_item, index| (1000**(index + 1)) }
  end

  # Method that is used to parse a string as JSON , if it fails will return nil
  # @see JSON#parse
  # @param [string] res The string that will be parsed as JSON
  # @return [Hash, nil] Returns Hash object if the json parse succeeds or nil otherwise
  def parse_json(res)
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

  # instantiates an eventmachine http request object that will be used to make the htpp request
  # @see EventMachine::HttpRequest#initialize
  #
  # @param [String] url The URL that will be used in the HTTP request
  # @return [EventMachine::HttpRequest] Returns an http request object
  def em_request(url, method)
    options = {
          :connect_timeout => 5,        # default connection setup timeout
          :inactivity_timeout => 10,    # default connection inactivity (post-setup) timeout
         ssl: { 
            cipher_list: 'ALL', 
            verify_peer: false, 
          },
          :head => {
            "ACCEPT" => '*/*',
              "Connection" => "keep-alive"
          }
      }
    request_options = {
          :redirects => 5,              # follow 3XX redirects up to depth 5
         :keepalive => true,           # enable keep-alive (don't send Connection:close header)
          :head => {
              "ACCEPT" => '*/*'
          }
      }
    EventMachine::HttpRequest.new(url, options).send(method, request_options)
  end

  # This method is used to reqister a error callback to a HTTP request object
  # @see #callback_error
  # @param [EventMachine::HttpRequest] http The HTTP object that will be used for reqisteringt the error callback
  # @return [void]
  def register_error_callback(http)
    http.errback { |error| callback_error(error) }
  end

  # Callback that is used before returning the response the the instance
  #
  # @param [String] response The response that will be dispatched to the instance class that made the request
  # @return [String] Returns the response
  def callback_before_success(response)
    response
  end

  # Dispatches the response either to the final callback or to the block that will use the response
  # and then call the callback
  #
  # @param [String] res The response string that will be dispatched
  # @param [Lambda] callback The callback that is used to dispatch further the response
  # @param [Proc] block The block that is used for parsing response and then calling the callback
  # @return [void]
  def dispatch_http_response(res, callback, &block)
    res.blank? ? callback.call(res) : block.call(res)
  end

  # Method that is used to register a success callback to a http object
  # @see #callback_before_success
  # @see #dispatch_http_response
  #
  # @param [EventMachine::HttpRequest] http The HTTP object that will be used for registering the success callback
  # @param [Lambda] callback The callback that will be called if the response is blank
  # @param [Proc] block If the response is not blank, the block will receive the response
  # @return [void]
  def register_success_callback(http, callback, &block)
    http.callback do
      res = callback_before_success(http.response)
      dispatch_http_response(res, callback, &block)
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
  def fetch_data(url, callback = -> {}, &block)
    http = em_request(url, "get")
    register_error_callback(http)
    register_success_callback(http, callback, &block)
  end

  # Method that returns the logger used by the application
  #
  # @return [Logger]
  def logger
    app_settings.logger
  end
  
  def app_settings
    RubygemsDownloadShieldsApp.settings
  end

  # Method that is used to react when an error happens in a HTTP request
  # and prints out an error message
  #
  # @param [Object] error The error that was raised by the HTTP request
  # @return [void]
  def callback_error(error)
    logger.debug "Error during fetching data  : #{error.inspect}"
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

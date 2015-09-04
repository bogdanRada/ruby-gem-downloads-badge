# module that is used for formatting numbers using metrics
module Helper
module_function

  def metric_prefixes
    %w(k M G T P E Z Y)
  end

  def metric_power
    metric_prefixes.map.with_index { |_item, index| (1000**(index + 1)) }
  end

  def parse_json(res)
    JSON.parse(res)
  rescue JSON::ParserError
    nil
  end

  def print_to_output_buffer(response, output_buffer)
    return if output_buffer.closed?
    output_buffer << response
    output_buffer.close
  end

  def parse_gem_version(gem_version)
    return if gem_version.blank? || gem_version == 'stable'
    Versionomy.parse(gem_version)
  rescue Versionomy::Errors::ParseError
    return nil
  end

  def em_request(url)
    EventMachine::HttpRequest.new(url)
  end

  def register_error_callback(http)
    http.errback { |error| callback_error(error) }
  end

  def callback_before_success(response)
    response
  end

  def dispatch_http_response(res, callback, &block)
    res.blank? ? callback.call(res) : block.call(res)
  end

  def register_success_callback(http, callback, &block)
    http.callback do
      res = callback_before_success(http.response)
      dispatch_http_response(res, callback, &block)
    end
  end

  def fetch_data(url, callback = -> {}, &block)
    http = em_request(url).get
    register_error_callback(http)
    register_success_callback(http, callback, &block)
  end

  def callback_error(error)
    puts "Error during fetching data  : #{error.inspect}"
  end

  def stable_gem_versions(http_response)
    http_response.blank? ? [] : http_response.select { |val| val['prerelease'] == false }
  end

  def sorted_versions(versions)
    versions.blank? ? [] : versions.map { |val| val['number'] }.version_sort
  end

  def find_version(versions, number)
    number.blank? ? {} : versions.find { |val| val['number'] == number }
  end

  def last_version(sorted_versions)
    sorted_versions.blank? ? '' : sorted_versions.last
  end

  def get_latest_stable_version_details(http_response)
    versions = stable_gem_versions(http_response)
    sorted_versions = sorted_versions(versions)
    last_version_number = last_version(sorted_versions)
    find_version(versions, last_version_number)
  end
end

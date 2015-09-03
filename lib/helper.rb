#module that is used for formatting numbers using metrics
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

  def register_success_callback(http, &block)
    http.callback { block.call http.response }
  end

  def fetch_data(url, &block)
    http = em_request(url).get
    register_error_callback(http)
    register_success_callback(http, &block)
  end

  def callback_error(error)
    puts "Error during fetching data  : #{error.inspect}"
  end

  def stable_gem_versions(http_response)
    http_response.blank? ? [] : http_response.select { |val| val['prerelease'] == false }
  end

  # Description of method
  #
  # @param [Type] http_response describe http_response
  # @return [Type] description of returned object
  def all_gem_versions(http_response)
    versions = stable_gem_versions(http_response)
    sorted_versions(versions)
  end

  def sorted_versions(versions)
    versions.blank? ? [] : versions.map { |val| val['number'] }.version_sort
  end

  def find_version(versions, number)
    versions.find { |val| val['number'] == number }
  end

  def get_latest_stable_version_details(http_response)
    sorted_versions = all_gem_versions(http_response)
    last_version_number = sorted_versions.blank? ? '' : sorted_versions.last
    last_version_number.empty? ? {} : find_version(versions, number)
  end

end

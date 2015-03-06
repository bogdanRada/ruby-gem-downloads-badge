class RubygemsApi
  attr_accessor :errors, :gem_name, :gem_version, :downloads_count, :display_total

  def initialize(params)
    @gem_name = params['gem'].nil? ? nil : params['gem']
    @gem_version = params['version'].nil? ? nil : params['version']
    @display_total = !params['type'].nil? && params['type'] == 'total'
    @errors = []

    @downloads_count = nil
    parse_gem_version
  end

  def errors_exist?
    !@errors.empty? || @gem_name.nil?
  end

  def fetch_downloads_data(&block)
    return if errors_exist?
    fetch_gem_data_without_version(&block) if gem_no_version?
    fetch_specific_version_data(&block) if gem_specific_version?
    fetch_gem_stable_version_data(&block) if gem_stable_version?
  end

private

  def gem_no_version?
    !@gem_name.nil? && @gem_version.nil?
  end

  def gem_specific_version?
    !@gem_name.nil? && !@gem_version.nil? && @gem_version != 'stable'
  end

  def gem_stable_version?
    !@gem_name.nil? && !@gem_version.nil? && @gem_version == 'stable'
  end

  def fetch_gem_stable_version_data(&block)
    fetch_data("/api/v1/versions/#{@gem_name}.json") do |http_response|
      unless errors_exist?
        latest_stable_version_details = get_latest_stable_version_details(http_response)
        @downloads_count = latest_stable_version_details['downloads_count'] unless latest_stable_version_details.empty?
      end
      block.call
    end
  end

  def fetch_specific_version_data(&block)
    fetch_data("/api/v1/downloads/#{@gem_name}-#{@gem_version}.json") do |http_response|
      unless errors_exist?
        @downloads_count = http_response['version_downloads']
        @downloads_count = "#{http_response['total_downloads']}_total" if display_total
      end
      block.call
    end
  end

  def fetch_gem_data_without_version(&block)
    fetch_data("/api/v1/gems/#{@gem_name}.json") do |http_response|
      unless errors_exist?
        @downloads_count = http_response['version_downloads']
        @downloads_count = "#{http_response['downloads']}_total" if display_total
      end
      block.call
    end
  end

  def fetch_data(url, &block)
    return if errors_exist?
    http = EventMachine::HttpRequest.new("https://rubygems.org#{url}").get
    http.errback { |e| puts "Error during fetching data #{url} : #{e.inspect}" }
    http.callback do
      @res = http.response
      begin
        @res = JSON.parse(@res)
      rescue JSON::ParserError => e
        @errors << ["Error while parsing response from api : #{e.inspect}"]
      end
      block.call @res
    end
  end

  def parse_gem_version
    return if @gem_version.nil? || @gem_version == 'stable'
    begin
      Versionomy.parse(@gem_version)
    rescue Versionomy::Errors::ParseError
      @errors << ["Error while parsing gem version #{@gem_version} with Versionomy"]
    end
  end

  def get_latest_stable_version_details(http_response)
    versions = http_response.select { |val| val['prerelease'] == false } unless http_response.empty?
    version_numbers = versions.map { |val| val['number'] } unless versions.empty?
    sorted_versions = version_numbers.version_sort unless versions.empty?
    last_version_number = sorted_versions.empty? ? '' : sorted_versions.last
    last_version_number.empty? ? {} : versions.find { |val| val['number'] == last_version_number }
  end
end

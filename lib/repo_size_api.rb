require_relative './core_api'
# class used for connecting to runygems.org and downloading info about a gem
#
# @!attribute callback
#   @return [Proc] The callback that is executed after info is fetched
class RepoSizeApi < CoreApi
  # the base url to which the API will connect for fetching information about gems

  attr_reader :callback

  # Method used to instantiate an instance of RubygemsApi class with the params received from URL
  #
  # @param [Hash] params The params received from URL
  # @param [Proc] callback The callback that is executed after info is fetched
  # @return [void]
  def initialize(params, callback)
    @params = params.stringify_keys
    @callback = callback
    fetch_repo_data
  end

  # Method that checks if the gem is valid , and if it is will fetch the infromation about the gem
  # and pass the callback to the method . If is not valid the callback will be called with nil value
  # @see #valid?
  # @see #fetch_dowloads_info
  #
  # @param [Lambda] callback The callback that needs to be executed after the information is downloaded
  # @return [void]
  def fetch_repo_data
    if valid?
      fetch_info
    else
      @callback.call(nil)
    end
  end

  # This method will decide what API method need to be called, depending if we want the latest stable version,
  # a specific version or the latest one and passs the callback to the method call
  # @see #fetch_gem_data_without_version
  # @see #gem_stable_version?
  # @see #fetch_specific_version_data
  # @see #fetch_gem_stable_version_data
  #
  # @param [Lambda] callback The callback that needs to be executed after the information is downloaded
  # @return [void]
  def fetch_info
    fetch_data("https://api.github.com/repos/#{gem_path}", 'callback' => @callback) do |http_response|
      @callback.call format_to_filesize(http_response['size'].to_i)
    end
  end

  # Method that is used to determine if the gem is valid by checking his name and version
  # THe name is required and the version need to checked if is stable or sintactically valid
  # @see  #gem_with_version?
  #
  # @return [Boolean] Returns true if the gem is valid
  def valid?
    gem_path.present?
  end

  # This method is used to fetch the repo path from URL
  #
  # @return [String] Returns the path to repository
  def gem_path
    params.fetch('splat', ['']).join('')
  end

  # Method that is executed after we receive an successful response.
  # This method willt try and parse the response as JSON, and if the
  # parsing fails will return  nil
  #
  # @param [String] response The response received after successful HTTP request
  # @return [Hash, nil] Returns the response parsed to JSON, and if the parsing fails returns nil
  def callback_before_success(response)
    parse_json(response)
  end
end

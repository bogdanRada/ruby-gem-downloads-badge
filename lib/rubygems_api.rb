require_relative './helper'
# class used for connecting to runygems.org and downloading info about a gem
#
# @!attribute params
#   @return [Hash] The params received from URL
class RubygemsApi
  include Helper
  # the base url to which the API will connect for fetching information about gems
  BASE_URL = 'https://rubygems.org'

  attr_reader :params

  # Method used to instantiate an instance of RubygemsApi class with the params received from URL
  #
  # @param [Hash] params The params received from URL
  # @option params [String] :gem The name of the gem
  # @option params [String]:version The version of the gem
  # @option params [String] :type The type of display , if we want to display total downloads, this will have value 'total'
  # @return [void]
  def initialize(params)
    @params = params
    @downloads = nil
  end

  # Method that checks if the gem is valid , and if it is will fetch the infromation about the gem
  # and pass the callback to the method . If is not valid the callback will be called with nil value
  # @see #gem_is_valid?
  # @see #fetch_dowloads_info
  #
  # @param [Lambda] callback The callback that needs to be executed after the information is downloaded
  # @return [void]
  def fetch_downloads_data(callback)
    if gem_is_valid?
      fetch_dowloads_info(callback)
    else
      callback.call(nil)
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
  def fetch_dowloads_info(callback)
    if gem_version.blank?
      fetch_gem_data_without_version(callback)
    elsif !gem_stable_version?
      fetch_specific_version_data(callback)
    elsif gem_stable_version?
      fetch_gem_stable_version_data(callback)
    end
  end

  # Method that is used to determine if the gem is valid by checking his name and version
  # THe name is required and the version need to checked if is stable or sintactically valid
  # @see  #gem_with_version?
  #
  # @return [Boolean] Returns true if the gem is valid
  def gem_is_valid?
    gem_name.present? || gem_with_version?
  end

  # Returns the gem name from the params , otherwise nil
  #
  # @return [String, nil] Returns the gem name from the params , otherwise nil
  def gem_name
    @params.fetch('gem', nil)
  end
  # Returns the gem version from the params , otherwise nil
  #
  # @return [String, nil] Returns the gem version from the params , otherwise nil
  def gem_version
    @params.fetch('version', nil)
  end

  # Returns the display_type from the params , otherwise nil
  #
  # @return [String, nil] Returns the display_type  from the params , otherwise nil
  def display_type
    @params.fetch('type', nil)
  end

  # Method that checks if we need to display the total downloads
  #
  # @return [Boolean] Returns true if we need to display the total downloads
  def display_total
    display_type.present? && display_type == 'total'
  end

  # Method that checks if the version is 'stable'
  #
  # @return [Boolean] Returns true if the version is 'stable'
  def gem_stable_version?
    gem_version.present? && gem_version == 'stable'
  end

  # Method that checks if the version of the gem is sintactically valid
  #
  # @return [Boolean] returns true if the version of the gem is sintactically valid
  def gem_valid_version?
    gem_version.present? && parse_gem_version(gem_version).present?
  end

  # Method that check if the gem name and gem version are present and the gem version is either 'stable'
  # or sintactically valid
  # @see #gem_stable_version?
  # @see #gem_valid_version?
  #
  # @return [Boolean] returns true if the name and version of gem are present and valid sintactically
  def gem_with_version?
    gem_name.present? && gem_version.present? && (gem_stable_version? || gem_valid_version?)
  end

  # Method that downloads all the versions of a gem, finds the latest stable version and sends the downloads count to the callback
  # The count defers depending if we need to display total amount or not
  #
  # @param [Lambda] callback The callback that needs to be executed after the information is downloaded
  # @return [void]
  def fetch_gem_stable_version_data(callback)
    fetch_data("#{RubygemsApi::BASE_URL}/api/v1/versions/#{gem_name}.json", callback) do |http_response|
      latest_stable_version_details = get_latest_stable_version_details(http_response)
      downloads_count = latest_stable_version_details['downloads_count'] unless latest_stable_version_details.blank?
      callback.call downloads_count
    end
  end
  # Method that downloads information about a specifc version of a gem and send the count to the callback
  # The count defers depending if we need to display total amount or not
  #
  # @param [Lambda] callback The callback that needs to be executed after the information is downloaded
  # @return [void]
  def fetch_specific_version_data(callback)
    fetch_data("#{RubygemsApi::BASE_URL}/api/v1/downloads/#{gem_name}-#{gem_version}.json", callback) do |http_response|
      downloads_count = http_response['version_downloads']
      downloads_count = "#{http_response['total_downloads']}_total" if display_total
      callback.call downloads_count
    end
  end

  # Method that downloads information about the latest version and sends the count to the callback
  # The count defers depending if we need to display total amount or not
  #
  # @param [Lambda] callback The callback that needs to be executed after the information is downloaded
  # @return [void]
  def fetch_gem_data_without_version(callback)
    fetch_data("#{RubygemsApi::BASE_URL}/api/v1/gems/#{gem_name}.json", callback) do |http_response|
      downloads_count = http_response['version_downloads']
      downloads_count = "#{http_response['downloads']}_total" if display_total
      callback.call downloads_count
    end
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

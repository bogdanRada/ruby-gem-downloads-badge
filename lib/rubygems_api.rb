require_relative './helper'
# class used for connecting to runygems.org and downloading info about a gem
class RubygemsApi
  include Helper
  attr_reader :params

  def initialize(params)
    @params = params
  end

  def fetch_downloads_data(&block)
    block.call(nil) unless gem_is_valid?
    if gem_version.blank?
      fetch_gem_data_without_version(&block)
    elsif !gem_stable_version?
      fetch_specific_version_data(&block)
    elsif gem_stable_version?
      fetch_gem_stable_version_data(&block)
    end
  end

  private

  def gem_is_valid?
    if gem_version.present?
      parse_gem_version(gem_version).blank? ? false : true
    else
      gem_name.present? ? true : false
    end
  end

  def base_url
    'https://rubygems.org'
  end

  def gem_name
    @params.fetch('gem', nil)
  end

  def gem_version
    @params.fetch('version', nil)
  end

  def display_type
    @params.fetch('type', nil)
  end

  def display_total
    display_type.present? && display_type == 'total'
  end

  def gem_stable_version?
    gem_version.present? && gem_version == 'stable'
  end

  def fetch_gem_stable_version_data(&block)
    fetch_data("#{base_url}/api/v1/versions/#{gem_name}.json") do |http_response|
      unless http_response.blank?
        latest_stable_version_details = get_latest_stable_version_details(http_response)
        downloads_count = latest_stable_version_details['downloads_count'] unless latest_stable_version_details.empty?
      end
      block.call downloads_count
    end
  end

  def fetch_specific_version_data(&block)
    fetch_data("#{base_url}/api/v1/downloads/#{gem_name}-#{gem_version}.json") do |http_response|
      unless http_response.blank?
        downloads_count = http_response['version_downloads']
        downloads_count = "#{http_response['total_downloads']}_total" if display_total
      end
      block.call downloads_count
    end
  end

  def fetch_gem_data_without_version(&block)
    fetch_data("#{base_url}/api/v1/gems/#{gem_name}.json") do |http_response|
      unless http_response.blank?
        downloads_count = http_response['version_downloads']
        downloads_count = "#{http_response['downloads']}_total" if display_total
      end
      block.call downloads_count
    end
  end

  def register_success_callback(http, &block)
    http.callback { block.call parse_json(http.response) }
  end
end

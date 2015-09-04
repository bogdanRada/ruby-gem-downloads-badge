require_relative './helper'
# class used for connecting to runygems.org and downloading info about a gem
class RubygemsApi
  include Helper
  BASE_URL = 'https://rubygems.org'

  attr_reader :params

  def initialize(params)
    @params = params
    @downloads = nil
  end

  def fetch_downloads_data(callback)
    if gem_is_valid?
      fetch_dowloads_info(callback)
    else
      callback.call(nil)
    end
  end

private

  def fetch_dowloads_info(callback)
    if gem_version.blank?
      fetch_gem_data_without_version(callback)
    elsif !gem_stable_version?
      fetch_specific_version_data(callback)
    elsif gem_stable_version?
      fetch_gem_stable_version_data(callback)
    end
  end

  def gem_is_valid?
    gem_name.present? || gem_with_version?
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

  def gem_valid_version?
    gem_version.present? && parse_gem_version(gem_version).present?
  end

  def gem_with_version?
    gem_name.present? && gem_version.present? && (gem_stable_version? || gem_valid_version?)
  end

  def fetch_gem_stable_version_data(callback)
    fetch_data("#{RubygemsApi::BASE_URL}/api/v1/versions/#{gem_name}.json", callback) do |http_response|
      latest_stable_version_details = get_latest_stable_version_details(http_response)
      downloads_count = latest_stable_version_details['downloads_count'] unless latest_stable_version_details.blank?
      callback.call downloads_count
    end
  end

  def fetch_specific_version_data(callback)
    fetch_data("#{RubygemsApi::BASE_URL}/api/v1/downloads/#{gem_name}-#{gem_version}.json", callback) do |http_response|
      downloads_count = http_response['version_downloads']
      downloads_count = "#{http_response['total_downloads']}_total" if display_total
      callback.call downloads_count
    end
  end

  def fetch_gem_data_without_version(callback)
    fetch_data("#{RubygemsApi::BASE_URL}/api/v1/gems/#{gem_name}.json", callback) do |http_response|
      downloads_count = http_response['version_downloads']
      downloads_count = "#{http_response['downloads']}_total" if display_total
      callback.call downloads_count
    end
  end

  def callback_before_success(response)
    parse_json(response)
  end
end

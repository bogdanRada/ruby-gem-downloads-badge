require_relative './rubygems_api'
require_relative './config/initializers/version_sort'
require 'versionomy'

class GemVersionManager
  
  INVALID_COUNT = "invalid"

  @attrs = [:gem_name, :gem_version :downloads_count, :params, :rubygems_api, :error_parse_gem_version]
      
  attr_reader *@attrs
  attr_accessor *@attrs
  
  def initialize(params)
    @gem_name = params[:gem].nil? ? nil : params[:gem] ;
    @gem_version = params[:version].nil? ? nil : params[:version] ;
    @downloads_count = nil
    @error_parse_gem_version = false
    @params = params
    parse_gem_version
    @rubygems_api = RubygemsApi.new(self) unless invalid_count?
  end


  def display_total?
    !@params[:type].nil? && @params[:type] == "total"
  end
  
  def invalid_count?
    @downloads_count == GemVersionManager::INVALID_COUNT
  end
  
  
  def fetch_gem_downloads(&block)
    unless invalid_count?
     
      if (!@gem_name.nil?  && @gem_version.nil?)
        @rubygems_api.fetch_data("/api/v1/gems/#{@gem_name}.json") do  |http_response|
          unless invalid_count?
            @downloads_count = http_response['version_downloads']
            @downloads_count = "#{http_response['downloads']}_total" if display_total?
          end
          block.call 
        end
     
      
      elsif (!@gem_name.nil?  && !@gem_version.nil? && @gem_version!= "stable" && @error_parse_gem_version == false)
      
        @rubygems_api.fetch_data("/api/v1/downloads/#{@gem_name}-#{@gem_version}.json") do  |http_response|
          unless invalid_count?
            @downloads_count = http_response['version_downloads']
            @downloads_count = "#{http_response['total_downloads']}_total" if display_total?
          end
          block.call 
        end
     
      elsif (!@gem_name.nil?  && !@gem_version.nil? && @gem_version== "stable" && @error_parse_gem_version == false)
      
        @rubygems_api.fetch_data("/api/v1/versions/#{@gem_name}.json") do  |http_response|
          unless invalid_count?
            latest_stable_version_details = get_latest_stable_version_details(http_response)
            @downloads_count = latest_stable_version_details['downloads_count'] unless latest_stable_version_details.empty?
          end
          block.call 
        end
    
      end 
    
    end
  end
    

  private 
  
  def parse_gem_version
    if !@gem_version.nil? &&  @gem_version!= "stable"
      begin
        Versionomy.parse(@gem_version)
      rescue Versionomy::Errors::ParseError
        @downloads_count = GemVersionManager::INVALID_COUNT
        @error_parse_gem_version = true
      end
    end
  end
  
  def get_latest_stable_version_details(http_response)
    versions =  http_response.select{ |val|  val['prerelease'] == false } unless  http_response.empty?
    version_numbers =  versions.map{|val| val['number'] } unless versions.empty?
    sorted_versions = version_numbers.version_sort unless versions.empty?
    last_version_number =  sorted_versions.empty?  ? "" : sorted_versions.last 
    last_version_number.empty? ? {} : versions.detect {|val| val['number'] == last_version_number } 
  end
  
end
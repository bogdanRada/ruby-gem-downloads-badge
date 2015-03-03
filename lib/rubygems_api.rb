class RubygemsApi
  include Celluloid
  include Celluloid::Logger
  
  @attrs = [ :errors, :gem_name, :gem_version, :downloads_count,:display_total ]
      
  attr_reader *@attrs
  attr_accessor *@attrs
  
  def fetch_downloads_data(params, blk)
    work(params)
    if has_errors?
      blk.call "invalid"
    else
     
      if (!@gem_name.nil?  && @gem_version.nil?)
        fetch_gem_data_without_version(blk)
      
      elsif (!@gem_name.nil?  && !@gem_version.nil? && @gem_version!= "stable" )
        fetch_specific_version_data(blk)
     
      elsif (!@gem_name.nil?  && !@gem_version.nil? && @gem_version== "stable" )
        fetch_gem_stable_version_data(blk)
      end 
    
    end
  end
  
  
  private 
  
  def has_errors?
    !@errors.empty? || @gem_name.nil? 
  end
  
  def work(params)
    @gem_name =  params['gem'].nil? ? nil : params['gem'] ;
    @gem_version = params['version'].nil? ? nil : params['version'] ;
    @display_total = !params['type'].nil? && params['type'] == "total"
    @errors = []
   
    @downloads_count = nil
    parse_gem_version
  end
  
  def fetch_gem_stable_version_data(blk)
    fetch_data("/api/v1/versions/#{@gem_name}.json") do  |http_response|
      unless has_errors?
        latest_stable_version_details = get_latest_stable_version_details(http_response)
        @downloads_count = latest_stable_version_details['downloads_count'] unless latest_stable_version_details.empty?
      end
      blk.call @downloads_count
    end
  end
  
  def fetch_specific_version_data(blk)
    fetch_data("/api/v1/downloads/#{@gem_name}-#{@gem_version}.json") do  |http_response|
      unless has_errors?
        @downloads_count = http_response['version_downloads']
        @downloads_count = "#{http_response['total_downloads']}_total" if display_total
      end
      blk.call @downloads_count
    end
  end
  
  def fetch_gem_data_without_version(blk)
    fetch_data("/api/v1/gems/#{@gem_name}.json") do  |http_response|
      unless has_errors?
        @downloads_count = http_response['version_downloads']
        @downloads_count = "#{http_response['downloads']}_total" if display_total
      end
      blk.call @downloads_count
    end
  end
  
    
  def fetch_data(url, &block)
    unless has_errors?
      data_url = "https://rubygems.org#{url}"
      fetcher = HttpFetcher.new
      @condition2 = Celluloid::Condition.new 
      blk = lambda do |sum|
        @condition2.signal(sum)
      end
      fetcher.fetch_async_json(blk ,data_url)
      @res =  @condition2.wait
      begin
        @res = JSON.parse(@res)
      rescue  JSON::ParserError => e
        @errors << ["Error while parsing response from api : #{e.inspect}"]
      end
      block.call @res 
    end
  end

  def parse_gem_version
    if !@gem_version.nil? &&  @gem_version!= "stable"
      begin
        Versionomy.parse(@gem_version)
      rescue Versionomy::Errors::ParseError
        @errors << ["Error while parsing gem version #{@gem_version} with Versionomy"]
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

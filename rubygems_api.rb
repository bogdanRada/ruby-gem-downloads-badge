class RubygemsApi
  
  @attrs = [:manager, :api_conn, :errors, :gem_name, :gem_version]
      
  attr_reader *@attrs
  attr_accessor *@attrs

  def initialize(manager)
    @manager = manager
    @gem_name =  @manager.params[:gem].nil? ? nil :  @manager.params[:gem] ;
    @gem_version =  @manager.params[:version].nil? ? nil :  @manager.params[:version] ;
    @errors = []
    parse_gem_version
     
    unless has_errors?
      @api_conn = Faraday.new "https://rubygems.org", :ssl => {:verify => false } do |con|
        con.request :url_encoded
        con.response :logger
        con.adapter :em_http
      end
    end
  end
  
  def has_errors?
    !@errors.empty?
  end
 
   
  def fetch_gem_downloads(&block)
    unless has_errors?
     
      if (!@gem_name.nil?  && @gem_version.nil?)
        fetch_data("/api/v1/gems/#{@gem_name}.json") do  |http_response|
          unless has_errors?
            @manager.downloads_count = http_response['version_downloads']
            @manager.downloads_count = "#{http_response['downloads']}_total" if @manager.display_total?
          end
          block.call 
        end
     
      
      elsif (!@gem_name.nil?  && !@gem_version.nil? && @gem_version!= "stable" )
      
        fetch_data("/api/v1/downloads/#{@gem_name}-#{@gem_version}.json") do  |http_response|
          unless has_errors?
            @manager.downloads_count = http_response['version_downloads']
            @manager.downloads_count = "#{http_response['total_downloads']}_total" if @manager.display_total?
          end
          block.call 
        end
     
      elsif (!@gem_name.nil?  && !@gem_version.nil? && @gem_version== "stable" )
      
        fetch_data("/api/v1/versions/#{@gem_name}.json") do  |http_response|
          unless has_errors?
            latest_stable_version_details = get_latest_stable_version_details(http_response)
            @manager.downloads_count = latest_stable_version_details['downloads_count'] unless latest_stable_version_details.empty?
          end
          block.call 
        end
    
      end 
    
    end
  end
  
  
  
  private 
  
  def fetch_data(url, &block)
    resp =@api_conn.get do |req|
      req.url url
      req.headers['Content-Type'] = 'application/json'
      req.options.timeout = 5           # open/read timeout in seconds
      req.options.open_timeout = 2
    end
    resp.on_complete {
      @res = resp.body 
      begin
        @res = JSON.parse(@res)
      rescue  JSON::ParserError => e
        @errors << ["Error while parsing response from api : #{e.inspect}"]
      end
      block.call @res 
      #request.env['async.callback'].call(response)
    }
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
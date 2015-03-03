class HttpFetcher  
  include Celluloid
  include Celluloid::Logger
  
  def fetch_async(options, block)
    Unirest.get(options[:url],   headers: options[:headers].present? ?  options[:headers] : {} ) {|response|
      block.call  response.body
    }
  end
  
end

class HttpFetcher  
  include Celluloid
  include Celluloid::Logger
  
  def fetch_async(blk, url, headers = {})
    Unirest.get(url,   headers: headers) {|response|
      blk.call  response.body
    }
  end
  
end

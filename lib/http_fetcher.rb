class HttpFetcher  
  
  def fetch_async(blk, url)
    Unirest.get(url) {|response|
      blk.call  response.body
    }
  end
  
  def fetch_async_json(blk, url)
    Unirest.get( url,  headers:{ "Accept" => "application/json" }) {|response|
      blk.call  response.body
    }
  end
end

class HttpFetcher
  include Celluloid::IO
  DEFAULT_OPTIONS = { ssl_socket_class: Celluloid::IO::SSLSocket}

  def fetch(url)
    # Note: For SSL support specify:
    # ssl_socket_class: Celluloid::IO::SSLSocket
    HTTP.get(url, HttpFetcher::DEFAULT_OPTIONS)
  end
  
  def fetch_json(url)
    HTTP.accept(:json).get(url,HttpFetcher::DEFAULT_OPTIONS)
  end
  
end

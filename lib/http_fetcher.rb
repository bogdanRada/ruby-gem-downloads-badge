class HttpFetcher
  include Celluloid::IO

  def fetch(url)
    # Note: For SSL support specify:
    # ssl_socket_class: Celluloid::IO::SSLSocket
    HTTP.get(url, socket_class: Celluloid::IO::TCPSocket)
  end
  
  def fetch_json(url)
    HTTP.accept(:json).get(url,  socket_class: Celluloid::IO::TCPSocket )
  end
  
end

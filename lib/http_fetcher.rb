class HttpFetcher
  include Celluloid
  include Celluloid::Logger
  include Celluloid::IO

  def fetch(url)
    # Note: For SSL support specify:
    # ssl_socket_class: Celluloid::IO::SSLSocket
    begin
    HTTP.get(url, socket_class: Celluloid::IO::TCPSocket)
    rescue => e
      debug(e)
      info(url)
    end
  end
end

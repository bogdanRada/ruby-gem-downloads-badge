# middleware used only in development for testing purposes
class RequestMiddleware
  def request(client, head, body)
    puts "HTTP request to #{client.req.uri}".inspect
    [head, body]
  end

  def response(resp)
    puts resp.response
    resp
  end
end

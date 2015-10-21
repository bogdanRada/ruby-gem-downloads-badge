
# middleware used only in development for testing purposes
class RequestMiddleware
  def request(client, head, body)
    puts "HTTP request to #{client.req.uri}".inspect
    puts [:client, client.inspect]
    puts [:headers, head.inspect]
    puts [:body, body.inspect]
    [head, body]
  end

  def response(resp)
    puts [:response, resp.inspect]
    puts [:response_body, resp.response.inspect]
    resp
  end
end

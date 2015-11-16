# middleware used only in development for testing purposes
class RequestMiddleware
  # Method that is used to debug requests to API's
  # The method receives the request object and prints it content to console
  #
  # @param [EventMachine::HttpRequest] client The Http request made to an API
  # @param [Hash] head The http headers sent to API
  # @param [String, nil] body The body sent to API
  # @return [Array<Hash,String>] Returns the http headers and the body
  def request(client, head, body)
    puts "HTTP request to #{client.req.uri}".inspect
    puts [:request_client, client.inspect]
    puts [:request_headers, head.inspect]
    puts [:request_body, body.inspect]
    [head, body]
  end

  # Method that is used to debug responses from API's
  # The method receives the response object and prints it content to console
  #
  # @param [EventMachine::HttpResponse] resp The Http response received from API
  # @return [EventMachine::HttpResponse]
  def response(resp)
    puts [:response_headers, resp.response_header.inspect]
    puts [:response_status, resp.response_header.status]
    puts [:response_object, resp.inspect]
    puts [:response_body, resp.response.inspect]
    resp
  end
end

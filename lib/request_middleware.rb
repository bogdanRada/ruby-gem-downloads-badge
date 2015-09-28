require_relative './helper'
# middleware used only in development for testing purposes
class RequestMiddleware
  include Helper
  def request(client, head, body)
    logger.debug "HTTP request to #{client.req.uri}".inspect
    [head, body]
  end

  def response(resp)
    logger.debug resp.response
    resp
  end
end

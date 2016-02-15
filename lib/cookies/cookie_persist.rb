require_relative './cookie_hash'
class CookiePersist
  def self.cookies
    Thread.current[:cookies] ||= []
  end

  def self.cookie_hash
    raise cookies.inspect if cookies.present?
    CookieHash.new.tap { |hsh|
      cookies.uniq.each { |c| hsh.add_cookies(c) }
    }
  end

  def request(client, head, body)
    head['cookie'] = self.class.cookie_hash.to_cookie_string
    #puts "Sending cookies: #{head['cookie']}"
    [head, body]
  end

  def response(resp)
    resp
  end
end

# frozen_string_literal: true
# class used for handling cookies from http requests
class CookieHash
  extend Forwardable
  CLIENT_COOKIES = %w(path expires domain path secure HTTPOnly HttpOnly).freeze

  def initialize(hash = {})
    @hash = hash
  end

  def add_cookies(value)
    case value
      when Hash
        @hash.merge!(value)
      when String
        value.split('; ').each do |cookie|
          array = cookie.split('=')
          @hash[array[0].to_sym] = array[1]
        end
      else
        raise 'add_cookies only takes a Hash or a String'
    end
  end

  def expire_time
    DateTime.parse(@hash[:expires]).in_time_zone
  end

  def to_cookie_string
    @hash.delete_if { |key, _value| CLIENT_COOKIES.include?(key.to_s) }.map { |key, value| "#{key}=#{value}" }.join('; ')
  end
end

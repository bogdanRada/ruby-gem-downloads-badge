# frozen_string_literal: true
# class used for handling cookies from http requests
# @!attribute hash
#   @return [Hash] The Hash that will contain the data about the cookie
class CookieHash
  extend Forwardable

  # constant that is used for filtering the cookie data (@hash) from unwanted values
  CLIENT_COOKIES = %w(path expires domain path secure HTTPOnly HttpOnly).freeze

  # Initializes the instance with empty hash by default
  #
  # @param [Hash] hash The Hash that will contain the data about the cookie
  # @return [void]
  def initialize(hash = {})
    @hash = hash
  end

  # parses the value received, if is is a hash, will merge it with the @hash instance, otherwise, will parse
  # the string by splitting it and assigning the keys and the values to the hash
  #
  # @param [Hash, String] value The value that will be parsed and merged into the hash
  # @return [void]
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

  # returns the expire time of the cookie that has been already parsed
  #
  # @return [Time] returns the expire time of the cookie that has been parsed
  def expire_time
    DateTime.parse(@hash[:expires]).in_time_zone
  end

  # returns the cookie value as a String, filtering unwanted values
  #
  # @return [String] returns cookie value, filtering the unwanted values
  def to_cookie_string
    @hash.delete_if { |key, _value| CLIENT_COOKIES.include?(key.to_s) }.map { |key, value| "#{key}=#{value}" }.join('; ')
  end
end

# frozen_string_literal: true

# class used for handling cookies from http requests
# @!attribute hash
#   @return [Hash] The Hash that will contain the data about the cookie
class CookieHash
  # constant that is used for filtering the cookie data (@hash) from unwanted values
  CLIENT_COOKIES = %w[path expires domain secure httponly max-age session samesite].freeze

  attr_reader :hash

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
      parsed = value.each_with_object({}) do |(key, val), memo|
        key = special?(key.to_s) ? key.to_s.strip.downcase : key.to_s
        memo[key] = val
      end
      @hash.merge!(parsed)
    when String
      value.split(';').each do |cookie|
        array = cookie.split('=')
        key = special?(array[0]) ? array[0].to_s.strip.downcase : array[0].to_s
        @hash[key] = array[1]
      end
    else
      raise 'add_cookies only takes a Hash or a String'
    end
  end

  # returns the expire time of the cookie that has been already parsed
  #
  # @return [Time] returns the expire time of the cookie that has been parsed
  def expiration
    val = if (max_age = @hash['max-age'].to_s.strip).present?
            Time.zone.now + max_age.to_i
          else
            expire_time
          end
    val&.gmtime
  end

  # returns the cookie value as a String, filtering unwanted values
  #
  # @return [String] returns cookie value, filtering the unwanted values
  def to_cookie_string
    data = @hash.delete_if { |key, _value| special?(key.to_s) }
    data.map { |key, value| "#{key}=#{value}" }.join('; ')
  end

  private

  # returns the expire time of the cookie that has been already parsed
  #
  # @return [Time] returns the expire time of the cookie that has been parsed
  def expire_time
    return if (val = @hash['expires'].to_s.strip).blank?
    Time.zone.parse(val)
  end

  # checks if the given key is in the list of special attributes to be handled
  #
  # @param [String, nil] key The key that will be verified
  # @return [Boolean] returns true if the key is in the special attributes list
  def special?(key)
    CLIENT_COOKIES.include?(key.to_s.strip.downcase)
  end
end

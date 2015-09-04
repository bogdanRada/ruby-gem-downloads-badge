# extending enumerable with methods
module Enumerable
  # Sorts gem versions
  #
  # @return [Array] Arary of versions sorted
  # @api public
  def version_sort
    sort_by do |key, _val|
      gsub_factory_versions(key)
    end
  end

  # tries to parse a version and retuns an array of versions sorted
  # @see #sort_versions
  #
  # @param [String] key The version as a string
  # @return [Array<String>] Returns the sorted versions parsed from string provided
  # @api public
  def gsub_factory_versions(key)
    version_string = key.gsub(/_SP/, '.').gsub(/_Factory/, '_100')
    sort_versions(version_string)
  end

  # Returns an array of sorted versions from a string
  # @see #version_is_float?
  # @param [String] version_string The version of the gem as a string
  # @return [Array<String>] Returns an array of sorted versions
  # @api public
  def sort_versions(version_string)
    version_string.split(/_/).map { |version| version_is_float?(version) }
  end

# function that makes the methods incapsulated as utility functions

module_function

  # if the version is a float number, will return the float number, otherwise the string in downcase letters
  #
  # @param [String] version The version of the gem as a string
  # @return [String, Float] if the version is a float number, will return the float number, otherwise the string in downcase letters
  # @api public
  def version_is_float?(version)
    version =~ /\A\d+(\.\d+)?\z/ ? -(version.to_f) : version.downcase
  end
end

# frozen_string_literal: true

# extending enumerable with methods
module Enumerable
  # Sorts gem versions
  #
  # @return [Array] Array of versions sorted
  # @api public
  def version_sort
    sort_by do |key, _val|
      gsub_factory_versions(key)
    end
  end

  # tries to parse a version and returns an array of versions sorted
  # @see #sort_versions
  #
  # @param [String, Enumerable] key The version as a string
  # @return [Array<String>] Returns the sorted versions parsed from string provided
  # @api public
  def gsub_factory_versions(key)
    version_string = key.gsub(/_SP/, '.').gsub(/_Factory/, '_100')
    sort_versions(version_string)
  end

  # Returns an array of sorted versions from a string
  # @see #version_is_float?
  # @param [String] version_string The version of the gem as a string
  # @return [Array<String>, Array<Float>] Returns an array of sorted versions
  # @api public
  def sort_versions(version_string)
    version_string.split(/_/).map { |version| version_to_float(version) }
  end

  # function that makes the methods encapsulated as utility functions

  module_function

  # if the version is a float number, will return the float number, otherwise the string in downcase letters
  #
  # @param [String] version The version of the gem as a string
  # @return [String, Float] if the version is a float number, will return the float number, otherwise the string in downcase letters
  # @api public
  def version_to_float(version)
    version =~ /\A\d+(\.\d+)?\z/ ? -version.to_f : version.downcase
  end
end

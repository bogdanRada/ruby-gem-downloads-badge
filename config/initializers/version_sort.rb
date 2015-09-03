# extending enumerable with methods
module Enumerable
  # Sorts gem versions
  #
  # @return [Array] Arary of versions sorted
  def version_sort
    sort_by do |key, _val|
      gsub_factory_versions(key)
    end
  end

  def gsub_factory_versions(key)
    version_string = key.gsub(/_SP/, '.').gsub(/_Factory/, '_100')
    sort_versions(version_string)
  end

  def sort_versions(version_string)
    version_string.split(/_/).map { |version| version_is_float?(version) }
  end

module_function

  def version_is_float?(version)
    version =~ /\A\d+(\.\d+)?\z/ ? -(version.to_f) : version.downcase
  end

end

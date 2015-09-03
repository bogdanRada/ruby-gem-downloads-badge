# extending enumerable with methods
module Enumerable
  # Sorts gem versions
  #
  # @return [Array] Arary of versions sorted
  def version_sort
    sort_by do |key, _val|
      key.gsub(/_SP/, '.').gsub(/_Factory/, '_100').split(/_/) \
        .map { |version| version =~ /\A\d+(\.\d+)?\z/ ? -(version.to_f) : version.downcase }
    end
  end
end

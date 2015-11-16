require_relative './helper'
# class used for formatting numbers
# class used to download badges from shields.io
#
# @!attribute number
#   @return [Number] The number that will be formatted in different format
# @!attribute params
#   @return [Hash] The params that are used for formatting the number display
class NumberFormatter
  include Helper
  attr_reader :number, :params

  # Method used for instantiating the NumberFormatter with the number that will be used
  # and a boolean value that will decide if we format in metric format or using delimiters
  # If the number is blank the number will be set to 0
  #
  # @param [Number] number  The number that will be formatted in different format
  # @param [Hash] params A boolean value that will decide if we format using metrics or delimiters
  # @return [void]
  def initialize(number, params)
    @number = number.present? ? number : 0
    @params = params
  end

  # Method that is used to decide which format to use depending on the instance
  # variable display_metric. if the variable is true will display using metrics otherwise
  # using delimiters
  # @see #number_with_metric
  # @see #number_with_delimiter
  #
  # @return [String] Returns the number formatted with metrics if 'display_metric' instance variable is true, otherwise using delimiters
  def to_s
    @params.fetch('metric', false).present? ? number_with_metric : number_with_delimiter
  end

  # Method used to print a number using metrics
  #
  # @return [String] Returns the formatted number in metrics format
  def number_with_metric
    index = metric_prefixes.size - 1
    while index >= 0
      limit = metric_power[index]
      if @number > limit
        return "#{((@number / limit).to_f.round)}#{metric_prefixes[index]}"
      end
      index -= 1
    end
  end

  # Description of method
  #
  # @param [String] delimiter = ',' The delimiter that is used for number greater than 1000
  # @param [String] separator = '.' The separator is used for float numbers to separate zecimals
  # @return [String] Returns the formatted number using delimiters and separators
  def number_with_delimiter(delimiter = ',', separator = '.')
    parts = @number.to_s.split('.')
    parts[0].gsub!(/(\d)(?=(\d\d\d)+(?!\d))/, "\\1#{delimiter}")
    parts.join separator
  rescue
    @number.to_s
  end
end

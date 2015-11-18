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

  # Method that is used to decide if the number is from a rubygems API call
  #
  # @return [Boolean] Returns true or false depending if params have key 'api' with value 'rubygems'
  def for_rubygems_api?
    @params['api'] == 'rubygems'
  end

  # Method that is used to decide if the number is from a Github API call
  #
  # @return [Boolean] Returns true or false depending if params have key 'api' with value 'github'
  def for_github_api?
    @params['api'] == 'github'
  end

  # Method that is used to decide if number can be displayed using metrics
  # @see #for_rubygems_api
  #
  # @return [Boolean] Returns true or false depending if action is available
  def can_display_metric?
    for_rubygems_api? && @params.fetch('metric', false).present?
  end

  # Method that is used to decide if total can be shown on badge
  # @see #for_rubygems_api
  # @see #display_total
  #
  # @return [Boolean] Returns true or false depending if action is available
  def can_display_total?
    for_rubygems_api? && display_total
  end

  # Method that is used to append '_total' to number if action is available
  # @see #can_display_total
  #
  # @return [String] Returns string '_total' or from params (if has key total_label), or empty string otherwise
  def number_text
    can_display_total? ? "_#{@params.fetch('total_label', 'total').tr('-', '_')}" : ''
  end

  # Method that is used to decide which format to use depending on the instance
  # variable display_metric. if the variable is true will display using metrics otherwise
  # using delimiters
  # @see #number_with_metric
  # @see #number_with_delimiter
  #
  # @return [String] Returns the number formatted with metrics if 'display_metric' instance variable is true, otherwise using delimiters
  def to_s
    nr = can_display_metric? ? number_with_metric : number_with_delimiter
    nr = format_to_filesize if for_github_api?
    "#{nr}#{number_text}"
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
    @number
  end

  # Formats the size into bytesize and returns it followed by the name of the bytesize
  #
  # @param [Float] bytes the bytes that need to translated to bits
  # @param [String] name The name of the bytesize
  # @return [String] Returns the format of the bytes with two decimal points followed by the name
  def byte_format(bytes, name)
    format('%.2f %s', (@number.to_f / (bytes / 1024)).round(2), name)
  end

  # Formats a number as a filesize
  # @see #byte_format
  # @return [String] The filesize of the number
  def format_to_filesize
    {
      'b'  => 1024,
      'kb' => 1024**2,
      'mb' => 1024**3,
      'gb' => 1024**4,
      'tb' => 1024**5,
      'pb' => 1024**6,
      'eb' => 1024**7
    }.each_pair do |name, bytes|
      next if @number >= bytes
      return byte_format(bytes, name)
    end
  end
end

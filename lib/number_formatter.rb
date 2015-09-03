# class used for formatting numbers
class NumberFormatter
  include Metrics
  attr_reader :number

  def initialize(number, display_metric)
    @number = number.present? ? number : 0
    @display_metric = display_metric
  end

  def to_s
    @number.to_s
  end

  def formatted_display
    @display_metric ? number_with_metric : number_with_delimiter
  end

  def number_with_metric
    index = metric_prefixes.size - 1
    while index >= 0
      limit = metric_power[index]
      if @number > limit
        return "#{((@number / limit).to_f.round)}#{metric_prefix[index]}"
      end
      index -= 1
    end
    @number.to_s
  end

  def number_with_delimiter(delimiter = ',', separator = '.')
    parts = @number.to_s.split('.')
    parts[0].gsub!(/(\d)(?=(\d\d\d)+(?!\d))/, "\\1#{delimiter}")
    parts.join separator
  rescue
    @number
  end
end

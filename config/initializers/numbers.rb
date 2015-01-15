def  number_with_metric(number) 
  metric_prefix = ['k', 'M', 'G', 'T', 'P', 'E', 'Z', 'Y']
  metric_power = metric_prefix.map.with_index { |item, index|  (1000**(index + 1)) }
  i = metric_prefix.size - 1
  while i >= 0  do
    limit = metric_power[i]
    if (number > limit) 
      number = (number / limit).to_f.round;
      return ''+number.to_s + metric_prefix[i].to_s;
    end  
    i -= 1
  end
  return ''+number.to_s;
end
  
  
def number_with_delimiter(number, delimiter=",", separator=".")
  begin
    parts = number.to_s.split('.')
    parts[0].gsub!(/(\d)(?=(\d\d\d)+(?!\d))/, "\\1#{delimiter}")
    parts.join separator
  rescue
    number
  end
end

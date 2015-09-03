#module that is used for formatting numbers using metrics
module Metrics

  def metric_prefixes
    %w(k M G T P E Z Y)
  end

  def metric_power
    metric_prefixes.map.with_index { |_item, index| (1000**(index + 1)) }
  end
end

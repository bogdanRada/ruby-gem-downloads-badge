# frozen_string_literal: true

class Hash
  def remove_blank_values
    each_with_object({}) do |(k, v), new_hash|
      unless v.blank? && v != false
        new_hash[k] = v.is_a?(Hash) ? v.remove_blank_values : v
      end
    end
  end

  def remove_blank_values!
    each_pair do |k, v|
      if v.blank? && v != false
        delete(k)
      elsif v.is_a?(Hash)
        v.remove_blank_values!
      end
    end
  end
end

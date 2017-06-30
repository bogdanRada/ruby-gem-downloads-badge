# frozen_string_literal: true

class Hash
  def remove_blank_values
    each_with_object({}) do |(key, value), new_hash|
      unless value.blank? && value != false
        new_hash[key] = value.is_a?(Hash) ? value.remove_blank_values : value
      end
    end
  end

  def remove_blank_values!
    each_pair do |key, value|
      if value.blank? && value != false
        delete(key)
      elsif value.is_a?(Hash)
        value.remove_blank_values!
      end
    end
  end
end

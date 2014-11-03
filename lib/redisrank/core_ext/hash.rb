class Hash

  def merge_to_max(key, value)
    return false unless value.is_a?(Numeric)
    self[key] = 0 unless self.has_key?(key)
    return false unless self[key].is_a?(Numeric)
    return false unless self[key] < value
    self[key] = value
    true
  end

  def merge_to_max!(hash)
    raise ArgumentError unless hash.is_a?(Hash)
    hash.each do |key, value|
      self[key] = value unless (self[key] || 0) > value
    end
    self
  end

end

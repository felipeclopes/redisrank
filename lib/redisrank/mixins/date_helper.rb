module Redisrank
  module DateHelper
    def to_redisrank(depth = nil)
      Redisrank::Date.new(self, depth)
    end
    alias :to_rs :to_redisrank
  end
end

class Date
  include Redisrank::DateHelper

  def to_time
    Time.parse(self.to_s)
  end

end

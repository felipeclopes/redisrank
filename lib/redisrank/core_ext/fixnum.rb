class Fixnum
  include Redisrank::DateHelper

  def to_time
    Time.at(self)
  end

end

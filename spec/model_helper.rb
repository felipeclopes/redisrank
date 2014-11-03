require "redisrank"

class ModelHelper1
  include Redisrank::Model


end

class ModelHelper2
  include Redisrank::Model

  depth :day
  store_event true
  hashed_label true

end

class ModelHelper3
  include Redisrank::Model

  connect_to :port => 8379, :db => 14

end

class ModelHelper4
  include Redisrank::Model

  scope "FancyHelper"
  expire :hour => 24*3600

end

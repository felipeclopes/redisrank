require "spec_helper"

describe Redisrank::Database do
  include Redisrank::Database

  it "should make #db method available when included" do
    db.should == Redisrank.redis
  end

end

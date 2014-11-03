require "spec_helper"

describe Redisrank::Scope do
  include Redisrank::Database

  before(:all) do
    db.flushdb
  end

  before(:each) do
    @name = "PageViews"
    @scope = Redisrank::Scope.new(@name)
  end

  it "should initialize properly" do
    @scope.to_s.should == @name
  end

  it "should increment next_id" do
    scope = Redisrank::Scope.new("Visitors")
    @scope.next_id.should == 1
    scope.next_id.should == 1
    @scope.next_id.should == 2
    scope.next_id.should == 2
  end

end

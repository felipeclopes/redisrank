require "spec_helper"

describe Redisrank::Result do

  it "should should initialize properly" do
    options = {:from => "from", :till => "till"}
    result = Redisrank::Result.new(options)
    result.from.should == "from"
    result.till.should == "till"
  end

  it "should have merge_to_max method" do
    result = Redisrank::Result.new
    result[:world].should be_nil
    result.merge_to_max(:world, 3)
    result[:world].should == 3
    result.merge_to_max(:world, 8)
    result[:world].should == 8
    result.merge_to_max(:world, 3)
    result[:world].should == 8
  end

end

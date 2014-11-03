require "spec_helper"

describe Redisrank::Collection do

  it "should initialize properly" do
    options = {:from => "from", :till => "till", :depth => "depth"}
    result = Redisrank::Collection.new(options)
    result.from.should == options[:from]
    result.till.should == options[:till]
    result.depth.should == options[:depth]
  end

  it "should have a rank property" do
    col = Redisrank::Collection.new()
    col.rank.should == {}
    col.rank = {:foo => "bar"}
    col.rank.should == {:foo => "bar"}
  end

end

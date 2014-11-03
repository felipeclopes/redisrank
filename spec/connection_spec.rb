require "spec_helper"
include Redisrank

describe Redisrank::Connection do

  before(:each) do
    @redis = Redisrank.redis
  end

  it "should have a valid Redis client instance" do
    Redisrank.redis.should_not be_nil
  end

  it "should have initialized custom testing connection" do
    @redis.client.host.should == '127.0.0.1'
    @redis.client.port.should == 8379
    @redis.client.db.should == 15
  end

  it "should be able to set and get data" do
    @redis.set("hello", "world")
    expect(@redis.get("hello")).to eq("world")
    expect(@redis.del("hello")).to be 1
  end

  it "should be able to store hashes to Redis" do
    @redis.hset("hash", "field", "1")
    @redis.hget("hash", "field").should == "1"
    @redis.hincrby("hash", "field", 1)
    @redis.hget("hash", "field").should == "2"
    @redis.hincrby("hash", "field", -1)
    @redis.hget("hash", "field").should == "1"
    @redis.del("hash")
  end

  it "should be accessible from Redisrank module" do
    Redisrank.redis.should == Connection.get
    Redisrank.redis.should == Redisrank.connection
  end

  it "should handle multiple connections with refs" do
    Redisrank.redis.client.db.should == 15
    Redisrank.connect(:port => 8379, :db => 14, :ref => "Custom")
    Redisrank.redis.client.db.should == 15
    Redisrank.redis("Custom").client.db.should == 14
  end

  it "should be able to overwrite default and custom refs" do
    Redisrank.redis.client.db.should == 15
    Redisrank.connect(:port => 8379, :db => 14)
    Redisrank.redis.client.db.should == 14

    Redisrank.redis("Custom").client.db.should == 14
    Redisrank.connect(:port => 8379, :db => 15, :ref => "Custom")
    Redisrank.redis("Custom").client.db.should == 15

    # Reset the default connection to the testing server or all hell
    # might brake loose from the rest of the specs
    Redisrank.connect(:port => 8379, :db => 15)
  end

  # TODO: Test thread-safety
  it "should be thread-safe" do
    pending("need to figure out a way to test thread-safety")
  end

end

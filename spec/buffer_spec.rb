require "spec_helper"

describe Redisrank::Buffer do

  before(:each) do
    @class  = Redisrank::Buffer
    @buffer = Redisrank::Buffer.instance
    @key = double("Key", :to_s => "Scope/label:2011")
    @stats = {:count => 1, :views => 3}
    @depth_limit = :hour
    @opts = {:enable_grouping => true}
  end

  # let's cleanup after ourselves for the other specs
  after(:each) do
    @class.instance_variable_set("@instance", nil)
    @buffer.size = 0
  end

  it "should provide instance of itself" do
    @buffer.should be_a(@class)
  end

  it "should only buffer if buffer size setting is greater than 1" do
    @buffer.size.should == 0
    expect(@buffer.send(:should_buffer?)).to be false
    @buffer.size = 1
    @buffer.size.should == 1
    expect(@buffer.send(:should_buffer?)).to be false
    @buffer.size = 2
    @buffer.size.should == 2
    expect(@buffer.send(:should_buffer?)).to be true
  end

  it "should only flush buffer if buffer size is greater than or equal to buffer size setting" do
    @buffer.size.should == 0
    @buffer.send(:queue).size.should == 0
    expect(@buffer.send(:should_flush?)).to be false
    @buffer.send(:queue)[:hello] = 'world'
    @buffer.send(:incr_count)
    expect(@buffer.send(:should_flush?)).to be true
    @buffer.size = 5
    expect(@buffer.send(:should_flush?)).to be false
    3.times { |i|
      @buffer.send(:queue)[i] = i.to_s
      @buffer.send(:incr_count)
    }
    expect(@buffer.send(:should_flush?)).to be false
    @buffer.send(:queue)[4] = '4'
    @buffer.send(:incr_count)
    expect(@buffer.send(:should_flush?)).to be true
  end

  it "should force flush queue irregardless of result of #should_flush? when #reset_queue is called with true" do
    @buffer.send(:queue)[:hello] = 'world'
    @buffer.send(:incr_count)
    expect(@buffer.send(:should_flush?)).to be true
    @buffer.size = 2
    expect(@buffer.send(:should_flush?)).to be false
    @buffer.send(:reset_queue).should == {}
    @buffer.instance_variable_get("@count").should == 1
    @buffer.send(:reset_queue, true).should == {:hello => 'world'}
    @buffer.instance_variable_get("@count").should == 0
  end

  it "should #flush_data into Summary.update properly" do
    # the root level key value doesn't actually matter, but it's something like this...
    data = {'ScopeName/label/goes/here:2011::true:true' => {
      :key => @key,
      :stats => @stats,
      :depth_limit => @depth_limit,
      :opts => @opts
    }}
    item = data.first[1]
    Redisrank::Summary.should_receive(:update).with(@key, @stats, @depth_limit, @opts)
    @buffer.send(:flush_data, data)
  end

  it "should build #buffer_key correctly" do
    opts = {:enable_grouping => true, :label_indexing => false, :connection_ref => nil}
    @buffer.send(:buffer_key, @key, opts).should ==
      "#{@key.to_s}:connection_ref::enable_grouping:true:label_indexing:false"
    opts = {:enable_grouping => false, :label_indexing => true, :connection_ref => :omg}
    @buffer.send(:buffer_key, @key, opts).should ==
      "#{@key.to_s}:connection_ref:omg:enable_grouping:false:label_indexing:true"
  end

  describe "Buffering" do
    it "should store items on buffer queue" do
      expect(@buffer.store(@key, @stats, @depth_limit, @opts)).to be false
      @buffer.size = 5
      expect(@buffer.store(@key, @stats, @depth_limit, @opts)).to be true
      expect(@buffer.send(:queue).count).to eq(1)
      @buffer.send(:queue)[@buffer.send(:queue).keys.first][:stats][:count].should == 1
      @buffer.send(:queue)[@buffer.send(:queue).keys.first][:stats][:views].should == 3
      expect(@buffer.store(@key, @stats, @depth_limit, @opts)).to be true
      expect(@buffer.send(:queue).count).to eq(1)
      @buffer.send(:queue)[@buffer.send(:queue).keys.first][:stats][:count].should == 1
      @buffer.send(:queue)[@buffer.send(:queue).keys.first][:stats][:views].should == 3
    end
    
  end

end

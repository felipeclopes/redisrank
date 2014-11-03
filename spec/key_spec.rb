require "spec_helper"

describe Redisrank::Key do
  include Redisrank::Database

  before(:each) do
    db.flushdb
    @scope = "PageViews"
    @label = "about_us"
    @label_hash = Digest::SHA1.hexdigest(@label)
    @date = Time.now
    @key = Redisrank::Key.new(@scope, @label, @date, {:depth => :hour})
  end

  it "should initialize properly" do
    @key.scope.to_s.should == @scope
    @key.label.to_s.should == @label
    @key.label_hash.should == @label_hash
    @key.groups.map { |k| k.instance_variable_get("@label") }.should == @key.instance_variable_get("@label").groups
    @key.date.should be_instance_of(Redisrank::Date)
    @key.date.to_time.to_s.should == @date.to_s
  end

  it "should convert to string properly" do
    @key.to_s.should == "#{@scope}/#{@label}:#{@key.date.to_s(:hour)}"
    props = [:year, :month, :day, :hour, :min, :sec]
    props.each do
      @key.to_s(props.last).should == "#{@scope}/#{@label}:#{@key.date.to_s(props.last)}"
      props.pop
    end
    key = Redisrank::Key.new(@scope, nil, @date, {:depth => :hour})
    key.to_s.should == "#{@scope}:#{key.date.to_s(:hour)}"
  end

  it "should abide to hashed_label option" do
    @key = Redisrank::Key.new(@scope, @label, @date, {:depth => :hour, :hashed_label => true})
    @key.to_s.should == "#{@scope}/#{@label_hash}:#{@key.date.to_s(:hour)}"
    @key = Redisrank::Key.new(@scope, @label, @date, {:depth => :hour, :hashed_label => false})
    @key.to_s.should == "#{@scope}/#{@label}:#{@key.date.to_s(:hour)}"
  end

  it "should have default depth option" do
    @key = Redisrank::Key.new(@scope, @label, @date)
    @key.depth.should == :hour
  end

  it "should allow changing attributes" do
    # scope
    @key.scope.to_s.should == @scope
    @scope = "VisitorCount"
    @key.scope = @scope
    @key.scope.to_s.should == @scope
    # date
    @key.date.to_time.to_s.should == @date.to_s
    @date = Time.now
    @key.date = @date
    @key.date.to_time.to_s.should == @date.to_s
    # label
    @key.label.to_s.should == @label
    @key.label_hash == @label_hash
    @label = "contact_us"
    @label_hash = Digest::SHA1.hexdigest(@label)
    @key.label = @label
    @key.label.to_s.should == @label
    @key.label_hash == @label_hash
  end

  describe "Grouping" do
    before(:each) do
      @label = "message/public/offensive"
      @key = Redisrank::Key.new(@scope, @label, @date, {:depth => :hour})
    end

    it "should create a group of keys from label group" do
      label = 'message/public/offensive'
      result = [ "message/public/offensive",
                 "message/public",
                 "message" ]

      key = Redisrank::Key.new(@scope, label, @date, {:depth => :hour})

      key.groups.map { |k| k.label.to_s }.should == result
    end

    it "should know it's parent" do
      @key.parent.should be_a(Redisrank::Key)
      @key.parent.label.to_s.should == 'message/public'
      Redisrank::Key.new(@scope, 'hello', @date).parent.should be_nil
    end

    it "should update label index and return children" do
      db.smembers("#{@scope}#{Redisrank::LABEL_INDEX}#{@key.label.parent}").should == []
      @key.children.count.should be(0)

      @key.update_index                                                  # indexing 'message/publish/offensive'
      Redisrank::Key.new("PageViews", "message/public/die").update_index  # indexing 'message/publish/die'
      Redisrank::Key.new("PageViews", "message/public/live").update_index # indexing 'message/publish/live'

      members = db.smembers("#{@scope}#{Redisrank::LABEL_INDEX}#{@key.label.parent}") # checking 'message/public'
      members.count.should be(3)
      members.should include('offensive')
      members.should include('live')
      members.should include('die')

      key = @key.parent
      key.children.first.should be_a(Redisrank::Key)
      key.children.count.should be(3)
      key.children.map { |k| k.label.me }.should == members

      members = db.smembers("#{@scope}#{Redisrank::LABEL_INDEX}#{key.label.parent}") # checking 'message'
      members.count.should be(1)
      members.should include('public')

      key = key.parent
      key.children.count.should be(1)
      key.children.map { |k| k.label.me }.should == members

      members = db.smembers("#{@scope}#{Redisrank::LABEL_INDEX}") # checking ''
      members.count.should be(1)
      members.should include('message')

      key.parent.should be_nil
      key = Redisrank::Key.new("PageViews")
      key.children.count.should be(1)
      key.children.map { |k| k.label.me }.should include('message')
    end
  end

end

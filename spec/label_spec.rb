require "spec_helper"

describe Redisrank::Label do
  include Redisrank::Database

  before(:each) do
    db.flushdb
    @name = "about_us"
    @label = Redisrank::Label.new(@name)
  end

  it "should initialize properly and SHA1 hash the label name" do
    @label.name.should == @name
    @label.hash.should == Digest::SHA1.hexdigest(@name)
  end

  it "should store a label hash lookup key" do
    label = Redisrank::Label.new(@name, {:hashed_label => true}).save
    label.saved?.should be(true)
    db.hget(Redisrank::KEY_LABELS, label.hash).should == @name

    name = "contact_us"
    label = Redisrank::Label.create(name, {:hashed_label => true})
    label.saved?.should be(true)
    db.hget(Redisrank::KEY_LABELS, label.hash).should == name
  end

  it "should join labels" do
    include Redisrank
    label = Redisrank::Label.join('email', 'message', 'public')
    label.should be_a(Redisrank::Label)
    label.to_s.should == 'email/message/public'
    label = Redisrank::Label.join(Redisrank::Label.new('email'), Redisrank::Label.new('message'), Redisrank::Label.new('public'))
    label.should be_a(Redisrank::Label)
    label.to_s.should == 'email/message/public'
    label = Redisrank::Label.join('email', '', 'message', nil, 'public')
    label.should be_a(Redisrank::Label)
    label.to_s.should == 'email/message/public'
  end

  it "should allow you to use a different group separator" do
    include Redisrank
    Redisrank.group_separator = '|'
    label = Redisrank::Label.join('email', 'message', 'public')
    label.should be_a(Redisrank::Label)
    label.to_s.should == 'email|message|public'
    label = Redisrank::Label.join(Redisrank::Label.new('email'), Redisrank::Label.new('message'), Redisrank::Label.new('public'))
    label.should be_a(Redisrank::Label)
    label.to_s.should == 'email|message|public'
    label = Redisrank::Label.join('email', '', 'message', nil, 'public')
    label.should be_a(Redisrank::Label)
    label.to_s.should == 'email|message|public'
    Redisrank.group_separator = Redisrank::GROUP_SEPARATOR
  end

  describe "Grouping" do
    before(:each) do
      @name = "message/public/offensive"
      @label = Redisrank::Label.new(@name)
    end

    it "should know it's parent label group" do
      @label.parent.to_s.should == 'message/public'
      Redisrank::Label.new('hello').parent.should be_nil
    end

    it "should separate label names into groups" do
      @label.name.should == @name
      @label.groups.map { |l| l.to_s }.should == [ "message/public/offensive",
                                                   "message/public",
                                                   "message" ]

      @name = "/message/public/"
      @label = Redisrank::Label.new(@name)
      @label.name.should == @name
      @label.groups.map { |l| l.to_s }.should == [ "message/public",
                                                   "message" ]

      @name = "message"
      @label = Redisrank::Label.new(@name)
      @label.name.should == @name
      @label.groups.map { |l| l.to_s }.should == [ "message" ]
    end
  end

end

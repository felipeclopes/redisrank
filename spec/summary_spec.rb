require "spec_helper"

describe Redisrank::Summary do
  include Redisrank::Database

  before(:each) do
    db.flushdb
    @scope = "PageViews"
    @label = "about_us"
    @date = Time.now
    @key = Redisrank::Key.new(@scope, @label, @date, {:depth => :day})
    @stats = {"views" => 3, "visitors" => 2}
    @expire = {:hour => 24*3600}
  end

  it "should update a single summary properly" do
    Redisrank::Summary.send(:update_fields, @key, @stats, :hour)
    summary = db.zrevrange(@key.to_s(:hour), 0, -1, :with_scores => true)
    expect(summary.count).to be 2
    views = summary.first 
    expect(views.first).to eq('views')
    expect(views.last).to be 3.0
    visitors = summary.last
    expect(visitors.first).to eq('visitors')
    expect(visitors.last).to be 2.0

    Redisrank::Summary.send(:update_fields, @key, @stats, :hour)
    summary = db.zrevrange(@key.to_s(:hour), 0, -1, :with_scores => true)
    expect(summary.count).to be 2
    views = summary.first 
    expect(views.first).to eq('views')
    expect(views.last).to be 3.0
    visitors = summary.last
    expect(visitors.first).to eq('visitors')
    expect(visitors.last).to be 2.0
  end

  it "should set key expiry properly" do
    Redisrank::Summary.update_all(@key, @stats, :hour,{:expire => @expire})
    ((24*3600)-1..(24*3600)+1).should include(db.ttl(@key.to_s(:hour)))
    [:day, :month, :year].each do |depth|
      db.ttl(@key.to_s(depth)).should == -1
    end

    db.flushdb
    Redisrank::Summary.update_all(@key, @stats, :hour, {:expire => {}})
    [:hour, :day, :month, :year].each do |depth|
      db.ttl(@key.to_s(depth)).should == -1
    end
  end

  it "should update all summaries properly" do
    Redisrank::Summary.update_all(@key, @stats, :sec)
    [:year, :month, :day, :hour, :min, :sec, :usec].each do |depth|
      summary = db.zrevrange(@key.to_s(depth), 0, -1, :with_scores => true)
      if depth != :usec
        summary.count.should eq(2)
        views = summary.first 
        expect(views.first).to eq('views')
        expect(views.last).to be 3.0
        visitors = summary.last
        expect(visitors.first).to eq('visitors')
        expect(visitors.last).to be 2.0
      else
        summary.count.should eq(0)
      end
    end
  end

  it "should update summaries even if no label is set" do
    key = Redisrank::Key.new(@scope, nil, @date, {:depth => :day})
    Redisrank::Summary.send(:update_fields, key, @stats, :hour)
    summary = db.zrevrange(key.to_s(:hour), 0, -1, :with_scores => true)
    views = summary.first 
    expect(views.first).to eq('views')
    expect(views.last).to be 3.0
    visitors = summary.last
    expect(visitors.first).to eq('visitors')
    expect(visitors.last).to be 2.0
  end

  it "should inject stats key grouping summaries" do
    hash = { "count/hello" => 3, "count/world"   => 7,
             "death/bomb"  => 4, "death/unicorn" => 3,
             :"od/sugar"   => 7, :"od/meth"      => 8 }
    res = Redisrank::Summary.send(:inject_group_summaries, hash)
    res.should == { "count" => 10, "count/hello" => 3, "count/world"   => 7,
                    "death" => 7,  "death/bomb"  => 4, "death/unicorn" => 3,
                    "od"    => 15, :"od/sugar"   => 7, :"od/meth"      => 8 }
  end

  it "should properly store key group summaries" do
    stats = {"views" => 3, "visitors/eu" => 2, "visitors/us" => 4}
    Redisrank::Summary.update_all(@key, stats, :hour)
    summary = db.zrevrange(@key.to_s(:hour), 0, -1, :with_scores => true)
    summary.count.should eq(4)
    
    views = summary.select{|s| s.first == 'views'}.first
    visitors = summary.select{|s| s.first == 'visitors'}.first
    eu = summary.select{|s| s.first == 'visitors/eu'}.first
    us = summary.select{|s| s.first == 'visitors/us'}.first
    
    views.last.should == 3.0
    visitors.last.should == 6.0
    eu.last.should == 2.0
    us.last.should == 4.0
  end

  it "should not store key group summaries when option is disabled" do
    stats = {"views" => 3, "visitors/eu" => 2, "visitors/us" => 4}
    Redisrank::Summary.update_all(@key, stats, :hour, {:enable_grouping => false})
    summary = db.zrevrange(@key.to_s(:hour), 0, -1, :with_scores => true)
    summary.count.should eq(3)
    
    views = summary.select{|s| s.first == 'views'}.first
    eu = summary.select{|s| s.first == 'visitors/eu'}.first
    us = summary.select{|s| s.first == 'visitors/us'}.first

    views.last.should == 3.0
    eu.last.should == 2.0
    us.last.should == 4.0
  end

  it "should store label-based grouping enabled stats" do
    stats = {"views" => 3, "visitors/eu" => 2, "visitors/us" => 4}
    label = "views/about_us"
    key = Redisrank::Key.new(@scope, label, @date)
    Redisrank::Summary.update_all(key, stats, :hour)

    key.groups[0].label.to_s.should == "views/about_us"
    key.groups[1].label.to_s.should == "views"
    child1 = key.groups[0]
    parent = key.groups[1]

    label = "views/contact"
    key = Redisrank::Key.new(@scope, label, @date)
    Redisrank::Summary.update_all(key, stats, :hour)

    key.groups[0].label.to_s.should == "views/contact"
    key.groups[1].label.to_s.should == "views"
    child2 = key.groups[0]

    summary = db.zrevrange(child1.to_s(:hour), 0, -1, :with_scores => true)
    summary.count.should eq(4)
    
    views = summary.select{|s| s.first == 'views'}.first
    eu = summary.select{|s| s.first == 'visitors/eu'}.first
    us = summary.select{|s| s.first == 'visitors/us'}.first

    views.last.should == 3.0
    eu.last.should == 2.0
    us.last.should == 4.0

    summary = db.zrevrange(child2.to_s(:hour), 0, -1, :with_scores => true)
    summary.count.should eq(4)
    
    views = summary.select{|s| s.first == 'views'}.first
    eu = summary.select{|s| s.first == 'visitors/eu'}.first
    us = summary.select{|s| s.first == 'visitors/us'}.first

    views.last.should == 3.0
    eu.last.should == 2.0
    us.last.should == 4.0

    summary = db.zrevrange(parent.to_s(:hour), 0, -1, :with_scores => true)
    summary.count.should eq(4)
    
    views = summary.select{|s| s.first == 'views'}.first
    eu = summary.select{|s| s.first == 'visitors/eu'}.first
    us = summary.select{|s| s.first == 'visitors/us'}.first

    views.last.should == 3.0
    eu.last.should == 2.0
    us.last.should == 4.0
  end

end

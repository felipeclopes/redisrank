require "spec_helper"

describe Hash do

  it "should #merge_to_max values" do
    hash = {:count => 1}
    expect(hash.merge_to_max(:sum, 3)).to be true
    expect(hash).to eq({:count => 1, :sum => 3})
    expect(hash.merge_to_max(:count, 4)).to be true
    expect(hash).to eq({:count => 4, :sum => 3})
    expect(hash.merge_to_max(:count, 3)).to be false
    expect(hash.merge_to_max(:count, 'test')).to be false
    expect(hash.merge_to_max(:view, 'test')).to be false
    expect(hash).to eq({:count => 4, :sum => 3})
    hash[:view] = 'test'
    expect(hash.merge_to_max(:view, 3)).to be false
  end

  it "should #merge_to_max! hashes" do
    hash = { :count => 1, :sum => 2}

    expect(hash.clone.merge_to_max!({:mult => 3, :sum => 2, :count => 2})).to eq({:count => 2, :sum => 2, :mult => 3})
    expect(hash.clone.merge_to_max!({:mult => 3, :sum => 3, :count => 2})).to eq({:count => 2, :sum => 3, :mult => 3})
  end

end

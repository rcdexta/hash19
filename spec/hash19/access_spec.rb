require 'spec_helper'

describe 'Access Patterns for Hash19' do

  class Hash1
    include Hash19
    attributes :a, :b, :c
  end

  it 'should be able to access hash keys using dot notation' do
    hash1 = Hash1.new({a: 1, b: 2, c: 3})
    expect(hash1[:a]).to eq(1)
    expect(hash1[:b]).to eq(2)
    expect(hash1[:c]).to eq(3)
  end

  class Hash11
    include Hash19
    attributes :x, :y
    has_one :hash1, alias: :h
  end

  it 'should be able to work recursively' do
    hash11 = Hash11.new(hash1: {a: 1, b: 2, c: 3}, x: -1, y: -2)
    expect(hash11[:h][:a]).to eq(1)
  end

end
require 'spec_helper'

describe Hash19::Core do

  class Testable
    include Hash19
  end

  context 'declare attributes' do

    class Test1 < Testable
      attributes :a, :b, :c
    end

    it 'should be able to assign whitelisted attributes' do
      test = Test1.new(a: 1, b: 2, d: 4)
      expect(test.to_h).to eq('a' => 1, 'b' => 2)
    end

    it 'should return empty hash when no attributes match' do
      test = Test1.new(x: 1, y: 2, z: 4)
      expect(test.to_h).to eq({})
    end

    it 'should not break when an empty hash is passed' do
      test = Test1.new({})
      expect(test.to_h).to eq({})
    end

    it 'should not break when an empty array is passed' do
      test = Test1.new([])
      expect(test.to_h).to eq([])
    end

  end

  context 'Single attribute and aliases' do

    class Test2 < Testable
      attributes :a, :b, :c
      attribute :fake, key: :actual
      attribute :d
    end

    it 'should be able to assign attributes based on alias' do
      test = Test2.new("actual" => 1, "d" => 2)
      expect(test.to_h).to eq('fake' => 1, "d" => 2)
    end

    it 'should be able to use both attribute and attributes constructs' do
      test = Test2.new(actual: 1, a: 2, d: 3)
      expect(test.to_h).to eq('fake' => 1, 'a' => 2, 'd' => 3)
    end

    it 'should ignore alias if key not present' do
      test = Test2.new(a: 2)
      expect(test.to_h).to eq('a' => 2)
    end
  end

  context 'alias and key play' do
    class AliasPlay < Testable
      attribute :original, key: :alias
    end

    it 'should be able to resolve alias' do
      ap = AliasPlay.new('alias' => 1)
      expect(ap.to_h).to eq('original' => 1)
    end

    it 'should be able to resolve original if alias not found >:)' do
      ap = AliasPlay.new('original' => 1)
      expect(ap.to_h).to eq('original' => 1)
    end
  end

end

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

  end

  context 'Single attribute and aliases' do

    class Test2 < Testable
      attributes :a, :b, :c
      attribute :fake, key: :actual
      attribute :d
    end

    it 'should be able to assign attributes based on alias' do
      test = Test2.new(actual: 1)
      expect(test.to_h).to eq('fake' => 1)
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

  context 'has_one associations' do
    class Child < Testable
      attributes :x, :y, :z
    end

    class Parent < Testable
      attributes :p, :q
      has_one :child
    end

    it 'should be able to load the has_one child associations' do
      parent = Parent.new(p: 1, q: 2, child: {x: 1, p: 3})
      expect(parent.to_h).to eq('p' => 1, 'q' => 2, 'child' => {'x' => 1})
    end
  end

  context 'has_many associations' do
    class Wheel < Testable
      attributes :flat
    end

    class Bike < Testable
      attributes :cc
      has_many :wheels
    end

    it 'should be able to load the has_one child associations' do
      bike = Bike.new(cc: 150, wheels: [{name: 'one', flat: false}, {name: 'two', flat: true}])
      expect(bike.to_h).to eq('cc' => 150, 'wheels' => [{'flat' => false}, {'flat' => true}])
    end
  end

  context 'across modules' do
    module Bird
      class Duck < Testable
        attribute :quack
        has_many :feathers
      end

      class Feather < Testable
        attribute :light
      end
    end

    it 'should be able to resolve has_many relationship within modules' do
      duck = Bird::Duck.new(quack: true, feathers: [{light: true},{light: true}])
      expect(duck.to_h).to eq('quack' => true, 'feathers' => [{'light' => true}, {'light' => true}])
    end
  end

end

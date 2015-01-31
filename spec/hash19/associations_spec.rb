require 'spec_helper'

describe 'Associations' do

  class Testable
    include Hash19
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

    it 'should flag error when target class not present' do
      module Computer
        class Laptop < Testable
          attributes :model, :year
          has_one :keyboard
        end
      end

      expect { Computer::Laptop.new(model: 'MacBook Pro', year: 2013, keyboard: {keys: 101}) }.
          to raise_error('Class:<Computer::Keyboard> not defined! Unable to resolve association:<keyboard>')
    end

    it 'should support alternate key in payload for has_one' do
      class OtherParent < Testable
        attributes :x
        has_one :child, key: :offspring, class: 'Child'
      end

      parent = OtherParent.new(x: true, offspring: {x: 1, p: 3})
      expect(parent.to_h).to eq('x' => true, 'child' => {'x' => 1})
    end

    it 'should support association alias for has_one' do
      class AnotherParent < Testable
        attributes :x
        has_one :child, key: :offspring, alias: :junior
      end

      parent = AnotherParent.new(x: true, offspring: {x: 1, p: 3})
      expect(parent.to_h).to eq('x' => true, 'junior' => {'x' => 1})
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

    it 'should support alternate key in payload for has_many' do
      class OtherBike < Testable
        attributes :cc
        has_many :wheels, key: :discs
      end

      bike = OtherBike.new(cc: 150, discs: [{name: 'one', flat: false}, {name: 'two', flat: true}])
      expect(bike.to_h).to eq('cc' => 150, 'wheels' => [{'flat' => false}, {'flat' => true}])
    end

    it 'should support association alias for has_many' do
      class AnotherBike < Testable
        attributes :cc
        has_many :wheels, key: :discs, alias: :rings
      end

      bike = AnotherBike.new(cc: 150, discs: [{name: 'one', flat: false}, {name: 'two', flat: true}])
      expect(bike.to_h).to eq('cc' => 150, 'rings' => [{'flat' => false}, {'flat' => true}])
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
      duck = Bird::Duck.new(quack: true, feathers: [{light: true}, {light: false}])
      expect(duck.to_h).to eq('quack' => true, 'feathers' => [{'light' => true}, {'light' => false}])
    end
  end

  class Error < Testable
    attributes :error_id, :desc

    def self.find(id)
      {error_id: 500, desc: 'fatal error'}
    end

    def self.find_all
      [{error_id: 500, desc: 'fatal error'}, {error_id: 404, desc: 'not found'}]
    end
  end

  context 'has_one evaluation' do

    class Packet < Testable
      attributes :code, :error_id
      has_one :error, using: :error_id, trigger: ->(id) { Error.find id }
    end

    it 'should be able to call the trigger on has_one association' do
      packet = Packet.new(code: 500, error_id: 500)
      expect(packet.to_h).to eq('code' => 500, 'error_id' => 500, 'error' => {'error_id' => 500, 'desc' => 'fatal error'})
    end

  end

  context 'has_many evaluation' do

    class UDPPacket < Testable
      attributes :code, :error_id
      has_many :errors, using: :error_id, trigger: ->(id) { Error.find_all }, alias: 'all_errors'
    end

    it 'should be able to call the trigger on has_one association' do
      packet = UDPPacket.new(code: 500, error_id: 500)
      expect(packet.to_h).to eq('code' => 500, 'error_id' => 500, 'all_errors' => [{'error_id' => 500, 'desc' => 'fatal error'},
                                                                                   {'error_id' => 404, 'desc' => 'not found'}])
    end

  end

  context 'no id to lookup' do
    it 'should not fail if association key is not present' do
      class Jedi < Testable
        attributes :name
        has_one :padawan, using: :padawan_id, trigger: ->(id) { Padawan.find }
      end

      jedi = Jedi.new(name: 'Obi Wan Kenobi')
      expect(jedi.to_h).to eq({'name' => 'Obi Wan Kenobi'})
    end
  end

  context 'module and class with same name' do
    module SecretAgentService
      class SecretAgent < Testable
        attributes :code
        has_one :agency
      end
      class Agency < Testable
        attributes :name
      end
    end
    it 'should resolve class when association class and containing module have same name' do
      mi6 = SecretAgentService::SecretAgent.new({code: '007', agency: {name: 'MI6'}})
      expect(mi6.to_h).to eq({'code' => '007', 'agency' => {'name' => 'MI6'}})
    end
  end

end

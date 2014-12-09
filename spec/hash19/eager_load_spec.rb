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

end

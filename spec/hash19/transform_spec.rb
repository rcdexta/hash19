require 'spec_helper'

describe 'Transformers' do

  class Testable
    include Hash19
  end

  it 'should be able to call the transform function if present' do
    class Transformer < Testable
      attribute :name, transform: lambda { |x| x.upcase }
    end

    tt = Transformer.new(name: 'rc')
    expect(tt.to_h).to eq('name' => 'RC')
  end

  it 'should whine if transform function is not a proc' do
    class BadTransformer < Testable
      attribute :name, transform: {}
    end

    expect do
      tt = BadTransformer.new(name: 'rc')
      tt.to_h
    end.to raise_error
  end

end

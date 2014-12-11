require 'spec_helper'

describe Hash19::Lazy do

  class Sheep
    attr_accessor :name
    def shout
      "My name is #{@name || 'black sheep'}"
    end
  end

  it 'should be able to postpone execution of a block' do
    sheep = Sheep.new
    delayed_voice = Hash19::Lazy.new(-> { sheep.shout })
    sheep.name = 'Dolly'
    expect(delayed_voice.value).to eq('My name is Dolly')
  end
end
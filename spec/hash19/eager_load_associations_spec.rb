require 'spec_helper'

describe 'Eager Loading Associations' do

  class Testable
    include Hash19
  end

  class Error <  Testable
    attributes :error_id, :desc

    def self.find(id)
      {error_id: 500, desc: 'fatal error'}
    end

    def self.find_all(ids)
      [{error_id: 500, desc: 'fatal error'}, {error_id: 404, desc: 'not found'}]
    end
  end

  context 'has_one evaluation' do

    class Packet < Testable
      attributes :code, :error_id
      has_one :error, using: :error_id, trigger: lambda { |id| Error.find id }
    end

    it 'should be able to call the trigger on has_one association' do
      packet = Packet.new(code: 500, error_id: 500)
      expect(packet.to_h).to eq('code' => 500, 'error' => {'error_id' => 500, 'desc' => 'fatal error'})
    end

  end

  context 'has_many evaluation' do

    class UDPPacket < Testable
      attributes :code, :error_id
      has_many :errors, using: :error_id, trigger: lambda { |id| Error.find_all id }
    end

    it 'should be able to call the trigger on has_one association' do
      packet = UDPPacket.new(code: 500, error_id: 500)
      expect(packet.to_h).to eq('code' => 500, 'errors' => [{'error_id' => 500, 'desc' => 'fatal error'},
                                                           {'error_id' => 404, 'desc' => 'not found'}])
    end

  end

end

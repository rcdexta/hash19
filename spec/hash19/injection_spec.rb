require 'spec_helper'

describe 'Injections' do

  class Testable
    include Hash19
  end

  context 'has_many injection' do

    class SuperVillain < Testable
      attribute :name
      has_many :minions
      inject at: '$.minions', using: :fruit_id, reference: :id, trigger: lambda { |ids| Fruit.find_all ids }
    end

    class Minion < Testable
      attributes :name, :fruit_id
    end

    class Fruit < Testable
      attributes :id, :name

      def self.find_all(ids)
        [{id: 1, name: 'banana'}, {id: 2, name: 'apple'}, {id: 3, name: 'orange'}]
      end
    end


    it 'should be able to extract ids from a has_many association and inject' do
      gru_team = SuperVillain.new(name: 'Gru', minions: [{name: 'Poppadom', fruit_id: 1},
                                                         {name: 'Gelato', fruit_id: 2},
                                                         {name: 'Kanpai', fruit_id: 3}])
      expect(gru_team.to_h).to eq('name' => 'Gru', 'minions' => [{'name' => 'Poppadom', 'fruit' => {'id' => 1, 'name' => 'banana'}},
                                                                 {'name' => 'Gelato', 'fruit' => {'id' => 2, 'name' => 'apple'}},
                                                                 {'name' => 'Kanpai', 'fruit' => {'id' => 3, 'name' => 'orange'}}
                                                 ])
    end
  end

end
require 'rails_helper'

RSpec.describe SupplyMovement, type: :model do
  describe 'associations' do
    it 'belongs to supply' do
      movement = create(:supply_movement, :arrival)
      expect(movement.supply).to be_present
    end

    it 'can belong to from_location' do
      company = create(:company)
      movement = build(:supply_movement, :transfer, from_location: company, from_location_name: company.name)
      expect(movement.from_location).to eq(company)
    end

    it 'can belong to to_location' do
      company = create(:company)
      movement = build(:supply_movement, :transfer, to_location: company, to_location_name: company.name)
      expect(movement.to_location).to eq(company)
    end
  end

  describe 'validations' do
    it 'is valid with valid attributes' do
      supply = create(:supply)
      movement = build(:supply_movement, :arrival, supply: supply)
      expect(movement).to be_valid
    end

    it 'requires supply_id' do
      movement = build(:supply_movement, :arrival, supply: nil)
      expect(movement).not_to be_valid
      expect(movement.errors[:supply]).to be_present
    end

    it 'requires movement_type' do
      movement = build(:supply_movement, :arrival, movement_type: nil)
      expect(movement).not_to be_valid
      expect(movement.errors[:movement_type]).to be_present
    end

    it 'requires quantity' do
      movement = build(:supply_movement, :arrival, quantity: nil)
      expect(movement).not_to be_valid
      expect(movement.errors[:quantity]).to be_present
    end

    it 'requires movement_date' do
      movement = build(:supply_movement, :arrival, movement_date: nil)
      expect(movement).not_to be_valid
      expect(movement.errors[:movement_date]).to be_present
    end

    it 'validates inclusion of movement_type' do
      supply = create(:supply)
      expect(build(:supply_movement, supply: supply, movement_type: '入荷', to_location_name: '本社')).to be_valid
      expect(build(:supply_movement, supply: supply, movement_type: '消費', from_location_name: '本社')).to be_valid
      expect(build(:supply_movement, supply: supply, movement_type: '移動', from_location_name: '本社', to_location_name: '倉庫A')).to be_valid
    end

    it 'validates numericality of quantity' do
      supply = create(:supply)
      expect(build(:supply_movement, :arrival, supply: supply, quantity: 0)).not_to be_valid
      expect(build(:supply_movement, :arrival, supply: supply, quantity: -10)).not_to be_valid
      expect(build(:supply_movement, :arrival, supply: supply, quantity: 10)).to be_valid
    end
  end

  describe 'polymorphic locations' do
    let(:supply) { create(:supply) }
    let(:company) { create(:company) }

    it 'creates movement with Company as to_location' do
      movement = build(:supply_movement, :transfer,
                      supply: supply,
                      from_location_name: '本社',
                      to_location: company,
                      to_location_name: company.name,
                      quantity: 10)

      expect(movement.to_location).to eq(company)
      expect(movement.to_location_type).to eq('Company')
    end

    it 'creates movement with Company as from_location' do
      movement = build(:supply_movement, :transfer,
                      supply: supply,
                      from_location: company,
                      from_location_name: company.name,
                      to_location_name: '本社',
                      quantity: 20)

      expect(movement.from_location).to eq(company)
      expect(movement.from_location_type).to eq('Company')
    end
  end

  describe 'factory traits' do
    let(:supply) { create(:supply) }

    it 'creates arrival movement' do
      movement = create(:supply_movement, :arrival, supply: supply)
      expect(movement.movement_type).to eq('入荷')
      expect(movement.from_location_name).to be_nil
      expect(movement.to_location_name).to be_present
    end

    it 'creates consumption movement' do
      movement = create(:supply_movement, :consumption, supply: supply)
      expect(movement.movement_type).to eq('消費')
      expect(movement.from_location_name).to be_present
      expect(movement.to_location_name).to be_nil
    end

    it 'creates transfer movement' do
      movement = create(:supply_movement, :transfer, supply: supply)
      expect(movement.movement_type).to eq('移動')
      expect(movement.from_location_name).to be_present
      expect(movement.to_location_name).to be_present
    end
  end

  describe 'movement history' do
    let(:supply) { create(:supply) }

    it 'records multiple movements' do
      create(:supply_movement, :arrival, supply: supply, to_location_name: '本社', quantity: 50)
      create(:supply_movement, :consumption, supply: supply, from_location_name: '本社', quantity: 30)
      create(:supply_movement, :transfer, supply: supply, from_location_name: '本社', to_location_name: '倉庫A', quantity: 20)

      expect(supply.supply_movements.count).to eq(3)
    end
  end

  describe 'date filtering' do
    let(:supply) { create(:supply) }

    it 'allows filtering movements by date' do
      old_movement = create(:supply_movement, :arrival, supply: supply, movement_date: 1.month.ago)
      recent_movement = create(:supply_movement, :arrival, supply: supply, movement_date: Date.today)

      recent_movements = supply.supply_movements.where('movement_date >= ?', 1.week.ago)
      expect(recent_movements).to include(recent_movement)
      expect(recent_movements).not_to include(old_movement)
    end
  end

  describe 'notes field' do
    it 'stores movement notes' do
      movement = create(:supply_movement, :arrival, notes: 'テスト用の入荷処理')
      expect(movement.notes).to eq('テスト用の入荷処理')
    end

    it 'allows nil notes' do
      movement = create(:supply_movement, :arrival, notes: nil)
      expect(movement).to be_valid
    end
  end

  describe 'movement types' do
    let(:supply) { create(:supply) }

    context '入荷 (arrival)' do
      it 'records arrival to a location' do
        movement = create(:supply_movement, :arrival,
                         supply: supply,
                         to_location_name: '本社',
                         quantity: 100)

        expect(movement.movement_type).to eq('入荷')
        expect(movement.to_location_name).to eq('本社')
        expect(movement.from_location_name).to be_nil
      end
    end

    context '消費 (consumption)' do
      it 'records consumption from a location' do
        movement = create(:supply_movement, :consumption,
                         supply: supply,
                         from_location_name: '本社',
                         quantity: 50)

        expect(movement.movement_type).to eq('消費')
        expect(movement.from_location_name).to eq('本社')
        expect(movement.to_location_name).to be_nil
      end
    end

    context '移動 (transfer)' do
      it 'records transfer between locations' do
        movement = create(:supply_movement, :transfer,
                         supply: supply,
                         from_location_name: '本社',
                         to_location_name: '倉庫A',
                         quantity: 30)

        expect(movement.movement_type).to eq('移動')
        expect(movement.from_location_name).to eq('本社')
        expect(movement.to_location_name).to eq('倉庫A')
      end
    end
  end
end

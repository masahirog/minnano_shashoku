require 'rails_helper'

RSpec.describe Supply, type: :model do
  describe 'associations' do
    it 'has many supply_stocks' do
      supply = create(:supply)
      expect(supply).to respond_to(:supply_stocks)
    end

    it 'has many supply_movements' do
      supply = create(:supply)
      expect(supply).to respond_to(:supply_movements)
    end

    it 'destroys associated supply_stocks when destroyed' do
      supply = create(:supply, :with_stocks)
      expect { supply.destroy }.to change { SupplyStock.count }.by(-3)
    end
  end

  describe 'validations' do
    it 'is valid with valid attributes' do
      supply = build(:supply)
      expect(supply).to be_valid
    end

    it 'requires name' do
      supply = build(:supply, name: nil)
      expect(supply).not_to be_valid
      expect(supply.errors[:name]).to be_present
    end

    it 'requires sku' do
      supply = build(:supply, sku: nil)
      expect(supply).not_to be_valid
      expect(supply.errors[:sku]).to be_present
    end

    it 'requires category' do
      supply = build(:supply, category: nil)
      expect(supply).not_to be_valid
      expect(supply.errors[:category]).to be_present
    end

    it 'requires unit' do
      supply = build(:supply, unit: nil)
      expect(supply).not_to be_valid
      expect(supply.errors[:unit]).to be_present
    end

    it 'validates uniqueness of sku' do
      create(:supply, sku: 'TEST-0001')
      duplicate = build(:supply, sku: 'TEST-0001')
      expect(duplicate).not_to be_valid
      expect(duplicate.errors[:sku]).to be_present
    end
  end

  describe '#total_stock' do
    let(:supply) { create(:supply) }

    context 'when no supply stocks exist' do
      it 'returns 0' do
        expect(supply.total_stock).to eq(0)
      end
    end

    context 'when supply stocks exist' do
      before do
        create(:supply_stock, supply: supply, quantity: 50)
        create(:supply_stock, supply: supply, quantity: 30)
        create(:supply_stock, supply: supply, quantity: 20)
      end

      it 'returns the sum of all stock quantities' do
        expect(supply.total_stock).to eq(100)
      end
    end

    context 'when some stocks have zero quantity' do
      before do
        create(:supply_stock, supply: supply, quantity: 50)
        create(:supply_stock, supply: supply, quantity: 0)
        create(:supply_stock, supply: supply, quantity: 30)
      end

      it 'includes zero quantities in the sum' do
        expect(supply.total_stock).to eq(80)
      end
    end
  end

  describe '#needs_reorder?' do
    let(:supply) { create(:supply, reorder_point: 50) }

    context 'when reorder_point is not set' do
      let(:supply_without_reorder) { create(:supply, reorder_point: nil) }

      it 'returns false' do
        create(:supply_stock, supply: supply_without_reorder, quantity: 10)
        expect(supply_without_reorder.needs_reorder?).to be false
      end
    end

    context 'when total stock is below reorder point' do
      before do
        create(:supply_stock, supply: supply, quantity: 30)
      end

      it 'returns true' do
        expect(supply.needs_reorder?).to be true
      end
    end

    context 'when total stock equals reorder point' do
      before do
        create(:supply_stock, supply: supply, quantity: 50)
      end

      it 'returns true' do
        expect(supply.needs_reorder?).to be true
      end
    end

    context 'when total stock is above reorder point' do
      before do
        create(:supply_stock, supply: supply, quantity: 60)
      end

      it 'returns false' do
        expect(supply.needs_reorder?).to be false
      end
    end
  end

  describe 'categories' do
    it 'creates supply with disposable category' do
      supply = create(:supply, :disposable)
      expect(supply.category).to eq('使い捨て備品')
    end

    it 'creates supply with company_loan category' do
      supply = create(:supply, :company_loan)
      expect(supply.category).to eq('企業貸与備品')
    end

    it 'creates supply with restaurant_loan category' do
      supply = create(:supply, :restaurant_loan)
      expect(supply.category).to eq('飲食店貸与備品')
    end
  end

  describe 'factory traits' do
    it 'creates inactive supply' do
      supply = create(:supply, :inactive)
      expect(supply.is_active).to be false
    end

    it 'creates supply with stocks' do
      supply = create(:supply, :with_stocks)
      expect(supply.supply_stocks.count).to eq(3)
    end

    it 'creates supply with movements' do
      supply = create(:supply, :with_movements)
      expect(supply.supply_movements.count).to eq(5)
    end
  end
end

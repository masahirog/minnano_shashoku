require 'rails_helper'

RSpec.describe SupplyStock, type: :model do
  describe 'associations' do
    it 'belongs to supply' do
      stock = create(:supply_stock)
      expect(stock.supply).to be_present
    end

    it 'can belong to a location' do
      company = create(:company)
      stock = create(:supply_stock, location: company, location_name: company.name)
      expect(stock.location).to eq(company)
    end
  end

  describe 'validations' do
    it 'is valid with valid attributes' do
      supply = create(:supply)
      stock = build(:supply_stock, supply: supply)
      expect(stock).to be_valid
    end

    it 'requires supply_id' do
      stock = build(:supply_stock, supply: nil)
      expect(stock).not_to be_valid
      expect(stock.errors[:supply]).to be_present
    end

    it 'requires quantity' do
      stock = build(:supply_stock, quantity: nil)
      expect(stock).not_to be_valid
      expect(stock.errors[:quantity]).to be_present
    end

    it 'validates numericality of quantity' do
      stock = build(:supply_stock, quantity: -10)
      expect(stock).not_to be_valid
      expect(stock.errors[:quantity]).to be_present
    end

    it 'allows zero quantity' do
      supply = create(:supply)
      stock = build(:supply_stock, supply: supply, quantity: 0)
      expect(stock).to be_valid
    end
  end

  describe 'callbacks' do
    describe 'update_last_updated_at' do
      let(:stock) { create(:supply_stock, quantity: 50) }

      it 'updates last_updated_at when quantity changes' do
        old_time = stock.last_updated_at
        sleep 0.1
        stock.update(quantity: 60)
        expect(stock.last_updated_at).to be > old_time
      end

      it 'sets last_updated_at when created' do
        new_stock = create(:supply_stock)
        expect(new_stock.last_updated_at).to be_present
      end
    end
  end

  describe '#needs_reorder?' do
    let(:supply) { create(:supply, reorder_point: 50) }

    context 'when supply has no reorder point' do
      let(:supply_without_reorder) { create(:supply, reorder_point: nil) }
      let(:stock) { create(:supply_stock, supply: supply_without_reorder, quantity: 10) }

      it 'returns false' do
        expect(stock.needs_reorder?).to be false
      end
    end

    context 'when quantity is below reorder point' do
      let(:stock) { create(:supply_stock, supply: supply, quantity: 30) }

      it 'returns true' do
        expect(stock.needs_reorder?).to be true
      end
    end

    context 'when quantity equals reorder point' do
      let(:stock) { create(:supply_stock, supply: supply, quantity: 50) }

      it 'returns true' do
        expect(stock.needs_reorder?).to be true
      end
    end

    context 'when quantity is above reorder point' do
      let(:stock) { create(:supply_stock, supply: supply, quantity: 60) }

      it 'returns false' do
        expect(stock.needs_reorder?).to be false
      end
    end
  end

  describe '#location_display_name' do
    context 'with polymorphic location' do
      let(:company) { create(:company) }
      let(:stock) { create(:supply_stock, location: company, location_name: company.name) }

      it 'returns location name' do
        expect(stock.location_display_name).to eq(company.name)
      end
    end

    context 'without polymorphic location' do
      let(:stock) { create(:supply_stock, location_name: '本社') }

      it 'returns location_name' do
        expect(stock.location_display_name).to eq('本社')
      end
    end

    context 'with no location_name' do
      let(:stock) { build(:supply_stock, location_name: nil) }

      it 'returns default name' do
        expect(stock.location_display_name).to eq('本社')
      end
    end
  end

  describe 'polymorphic location' do
    context 'with no specific location (just location_name)' do
      let(:stock) { create(:supply_stock, location_name: '本社') }

      it 'creates stock with only location_name' do
        expect(stock.location_name).to eq('本社')
        expect(stock.location_type).to be_nil
        expect(stock.location_id).to be_nil
      end
    end

    context 'with Company location' do
      let(:company) { create(:company) }
      let(:stock) { create(:supply_stock, location: company, location_name: company.name) }

      it 'associates with Company' do
        expect(stock.location).to eq(company)
        expect(stock.location_type).to eq('Company')
        expect(stock.location_id).to eq(company.id)
      end
    end
  end

  describe 'factory traits' do
    it 'creates stock for headquarters' do
      stock = create(:supply_stock, :headquarters)
      expect(stock.location_name).to eq('本社')
    end

    it 'creates stock for warehouse_a' do
      stock = create(:supply_stock, :warehouse_a)
      expect(stock.location_name).to eq('倉庫A')
    end

    it 'creates low stock' do
      stock = create(:supply_stock, :low_stock)
      expect(stock.quantity).to eq(5)
    end

    it 'creates out of stock' do
      stock = create(:supply_stock, :out_of_stock)
      expect(stock.quantity).to eq(0)
    end

    it 'creates high stock' do
      stock = create(:supply_stock, :high_stock)
      expect(stock.quantity).to eq(100)
    end

    it 'creates stock with physical count' do
      stock = create(:supply_stock, :with_physical_count)
      expect(stock.physical_count).to be_present
    end
  end

  describe 'multiple stocks for same supply' do
    let(:supply) { create(:supply) }

    it 'allows multiple stocks in different locations' do
      stock1 = create(:supply_stock, supply: supply, location_name: '本社', quantity: 50)
      stock2 = create(:supply_stock, supply: supply, location_name: '倉庫A', quantity: 30)

      expect(supply.supply_stocks.count).to eq(2)
      expect(supply.total_stock).to eq(80)
    end
  end

  describe 'stock updates' do
    let(:stock) { create(:supply_stock, quantity: 100) }

    it 'updates quantity' do
      stock.update(quantity: 150)
      expect(stock.quantity).to eq(150)
    end

    it 'allows quantity to be set to zero' do
      stock.update(quantity: 0)
      expect(stock.quantity).to eq(0)
      expect(stock).to be_valid
    end

    it 'rejects negative quantity' do
      stock.update(quantity: -10)
      expect(stock.errors[:quantity]).to be_present
    end
  end
end

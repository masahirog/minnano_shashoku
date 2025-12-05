require 'rails_helper'

RSpec.describe DeliveryUser, type: :model do
  let(:delivery_company) { create(:delivery_company) }

  describe 'associations' do
    it 'belongs to delivery_company' do
      expect(described_class.reflect_on_association(:delivery_company).macro).to eq(:belongs_to)
    end

    it 'has many delivery_assignments' do
      expect(described_class.reflect_on_association(:delivery_assignments).macro).to eq(:has_many)
    end

    it 'has many delivery_reports' do
      expect(described_class.reflect_on_association(:delivery_reports).macro).to eq(:has_many)
    end

    it 'has many delivery_routes' do
      expect(described_class.reflect_on_association(:delivery_routes).macro).to eq(:has_many)
    end

    it 'has many push_subscriptions' do
      expect(described_class.reflect_on_association(:push_subscriptions).macro).to eq(:has_many)
    end
  end

  describe 'validations' do
    let(:user) { build(:delivery_user, delivery_company: delivery_company) }

    it 'is valid with valid attributes' do
      expect(user).to be_valid
    end

    it 'is not valid without a name' do
      user.name = nil
      expect(user).not_to be_valid
    end

    it 'is not valid without an email' do
      user.email = nil
      expect(user).not_to be_valid
    end

    it 'is not valid with a duplicate email' do
      create(:delivery_user, email: 'test@example.com', delivery_company: delivery_company)
      user.email = 'test@example.com'
      expect(user).not_to be_valid
    end

    it 'is not valid without a delivery_company' do
      user.delivery_company = nil
      expect(user).not_to be_valid
    end

    it 'is not valid with invalid role' do
      user.role = 'invalid_role'
      expect(user).not_to be_valid
    end
  end

  describe 'scopes' do
    let!(:active_driver) { create(:delivery_user, role: 'driver', is_active: true, delivery_company: delivery_company) }
    let!(:inactive_driver) { create(:delivery_user, :inactive, role: 'driver', delivery_company: delivery_company) }
    let!(:active_admin) { create(:delivery_user, :admin, is_active: true, delivery_company: delivery_company) }

    describe '.active' do
      it 'returns only active users' do
        expect(DeliveryUser.active).to include(active_driver, active_admin)
        expect(DeliveryUser.active).not_to include(inactive_driver)
      end
    end

    describe '.inactive' do
      it 'returns only inactive users' do
        expect(DeliveryUser.inactive).to include(inactive_driver)
        expect(DeliveryUser.inactive).not_to include(active_driver, active_admin)
      end
    end

    describe '.drivers' do
      it 'returns only drivers' do
        expect(DeliveryUser.drivers).to include(active_driver, inactive_driver)
        expect(DeliveryUser.drivers).not_to include(active_admin)
      end
    end

    describe '.admins' do
      it 'returns only admins' do
        expect(DeliveryUser.admins).to include(active_admin)
        expect(DeliveryUser.admins).not_to include(active_driver, inactive_driver)
      end
    end
  end

  describe '#active_for_authentication?' do
    context 'when user is active' do
      let(:user) { create(:delivery_user, is_active: true, delivery_company: delivery_company) }

      it 'returns true' do
        expect(user.active_for_authentication?).to be true
      end
    end

    context 'when user is inactive' do
      let(:user) { create(:delivery_user, :inactive, delivery_company: delivery_company) }

      it 'returns false' do
        expect(user.active_for_authentication?).to be false
      end
    end
  end

  describe '#admin?' do
    context 'when role is admin' do
      let(:user) { create(:delivery_user, :admin, delivery_company: delivery_company) }

      it 'returns true' do
        expect(user.admin?).to be true
      end
    end

    context 'when role is driver' do
      let(:user) { create(:delivery_user, role: 'driver', delivery_company: delivery_company) }

      it 'returns false' do
        expect(user.admin?).to be false
      end
    end
  end

  describe '#driver?' do
    context 'when role is driver' do
      let(:user) { create(:delivery_user, role: 'driver', delivery_company: delivery_company) }

      it 'returns true' do
        expect(user.driver?).to be true
      end
    end

    context 'when role is admin' do
      let(:user) { create(:delivery_user, :admin, delivery_company: delivery_company) }

      it 'returns false' do
        expect(user.driver?).to be false
      end
    end
  end
end

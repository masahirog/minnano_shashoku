require 'rails_helper'

RSpec.describe AssignDeliveryService, type: :service do
  let(:delivery_company) { create(:delivery_company) }
  let(:delivery_user) { create(:delivery_user, delivery_company: delivery_company) }
  let(:order) { create(:order, delivery_company: delivery_company, scheduled_date: Date.current) }
  let(:service) { described_class.new }

  describe '#assign' do
    context 'with valid parameters' do
      it 'creates a delivery assignment' do
        expect {
          service.assign(order.id, delivery_user.id)
        }.to change(DeliveryAssignment, :count).by(1)
      end

      it 'sets the correct attributes' do
        assignment = service.assign(order.id, delivery_user.id, scheduled_time: '10:00')

        expect(assignment.order).to eq(order)
        expect(assignment.delivery_user).to eq(delivery_user)
        expect(assignment.delivery_company).to eq(delivery_company)
        expect(assignment.scheduled_date).to eq(order.scheduled_date)
        expect(assignment.status).to eq('pending')
        expect(assignment.assigned_at).to be_present
      end

      it 'auto-assigns sequence_number' do
        assignment1 = service.assign(order.id, delivery_user.id)
        expect(assignment1.sequence_number).to eq(1)

        order2 = create(:order, delivery_company: delivery_company, scheduled_date: Date.current)
        assignment2 = service.assign(order2.id, delivery_user.id)
        expect(assignment2.sequence_number).to eq(2)
      end

      it 'allows manual sequence_number' do
        assignment = service.assign(order.id, delivery_user.id, sequence_number: 5)
        expect(assignment.sequence_number).to eq(5)
      end
    end

    context 'with invalid parameters' do
      it 'raises error when order already assigned' do
        service.assign(order.id, delivery_user.id)

        expect {
          service.assign(order.id, delivery_user.id)
        }.to raise_error(AssignDeliveryService::AssignmentError, /既に配送割当されています/)
      end

      it 'raises error when delivery_user is inactive' do
        inactive_user = create(:delivery_user, :inactive, delivery_company: delivery_company)

        expect {
          service.assign(order.id, inactive_user.id)
        }.to raise_error(AssignDeliveryService::AssignmentError, /無効な配送担当者/)
      end

      it 'raises error when delivery_company mismatch' do
        other_company = create(:delivery_company)
        other_user = create(:delivery_user, delivery_company: other_company)

        expect {
          service.assign(order.id, other_user.id)
        }.to raise_error(AssignDeliveryService::AssignmentError, /配送会社が一致しません/)
      end

      it 'raises error when order has no delivery_company' do
        order.update!(delivery_company_id: nil)

        expect {
          service.assign(order.id, delivery_user.id)
        }.to raise_error(AssignDeliveryService::AssignmentError, /配送会社が設定されていません/)
      end
    end
  end

  describe '#bulk_assign' do
    let(:orders) { create_list(:order, 3, delivery_company: delivery_company, scheduled_date: Date.current) }

    it 'assigns multiple orders' do
      expect {
        service.bulk_assign(orders.map(&:id), delivery_user.id)
      }.to change(DeliveryAssignment, :count).by(3)
    end

    it 'returns success and error counts' do
      result = service.bulk_assign(orders.map(&:id), delivery_user.id)

      expect(result[:total]).to eq(3)
      expect(result[:assigned]).to eq(3)
      expect(result[:failed]).to eq(0)
      expect(result[:success].size).to eq(3)
      expect(result[:errors]).to be_empty
    end

    it 'continues on partial failures' do
      # 1つ目の注文を事前に割り当て
      service.assign(orders.first.id, delivery_user.id)

      result = service.bulk_assign(orders.map(&:id), delivery_user.id)

      expect(result[:assigned]).to eq(2)
      expect(result[:failed]).to eq(1)
      expect(result[:errors].size).to eq(1)
    end
  end

  describe '#reassign' do
    let!(:assignment) { create(:delivery_assignment, order: order, delivery_user: delivery_user, delivery_company: delivery_company) }
    let(:new_user) { create(:delivery_user, delivery_company: delivery_company) }

    context 'with pending assignment' do
      it 'reassigns to new delivery_user' do
        service.reassign(assignment.id, new_user.id)
        assignment.reload

        expect(assignment.delivery_user).to eq(new_user)
      end
    end

    context 'with in_transit assignment' do
      before { assignment.update!(status: 'in_transit') }

      it 'raises error' do
        expect {
          service.reassign(assignment.id, new_user.id)
        }.to raise_error(AssignDeliveryService::AssignmentError, /配送中の案件は再割当できません/)
      end
    end

    context 'with completed assignment' do
      before { assignment.update!(status: 'completed') }

      it 'raises error' do
        expect {
          service.reassign(assignment.id, new_user.id)
        }.to raise_error(AssignDeliveryService::AssignmentError, /完了した配送は再割当できません/)
      end
    end
  end

  describe '#cancel' do
    let!(:assignment) { create(:delivery_assignment, order: order, delivery_user: delivery_user, delivery_company: delivery_company) }

    context 'with pending assignment' do
      it 'deletes the assignment' do
        expect {
          service.cancel(assignment.id)
        }.to change(DeliveryAssignment, :count).by(-1)
      end
    end

    context 'with in_transit assignment' do
      before { assignment.update!(status: 'in_transit') }

      it 'raises error' do
        expect {
          service.cancel(assignment.id)
        }.to raise_error(AssignDeliveryService::AssignmentError, /配送中の案件はキャンセルできません/)
      end
    end

    context 'with completed assignment' do
      before { assignment.update!(status: 'completed') }

      it 'raises error' do
        expect {
          service.cancel(assignment.id)
        }.to raise_error(AssignDeliveryService::AssignmentError, /完了した配送はキャンセルできません/)
      end
    end
  end
end

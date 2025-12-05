require 'rails_helper'

RSpec.describe 'Admin::DeliveryAssignments', type: :request do
  let(:admin_user) { create(:admin_user) }
  let(:delivery_company) { create(:delivery_company) }
  let(:delivery_user) { create(:delivery_user, delivery_company: delivery_company) }

  before do
    sign_in admin_user
  end

  describe 'GET /admin/delivery_assignments' do
    it 'returns http success' do
      get admin_delivery_assignments_path
      expect(response).to have_http_status(:success)
    end

    it 'displays delivery assignments list' do
      order = create(:order, delivery_company: delivery_company)
      assignment = create(:delivery_assignment, order: order, delivery_user: delivery_user, delivery_company: delivery_company)

      get admin_delivery_assignments_path
      expect(response.body).to include('配送割当')
    end

    context 'with filters' do
      let!(:assignment1) { create(:delivery_assignment, delivery_company: delivery_company, scheduled_date: Date.current) }
      let!(:assignment2) { create(:delivery_assignment, delivery_company: delivery_company, scheduled_date: Date.tomorrow) }

      it 'filters by scheduled_date' do
        get admin_delivery_assignments_path, params: { scheduled_date: Date.current }
        expect(response).to have_http_status(:success)
      end

      it 'filters by delivery_company_id' do
        get admin_delivery_assignments_path, params: { delivery_company_id: delivery_company.id }
        expect(response).to have_http_status(:success)
      end

      it 'filters by status' do
        get admin_delivery_assignments_path, params: { status: 'pending' }
        expect(response).to have_http_status(:success)
      end
    end
  end

  describe 'GET /admin/delivery_assignments/:id' do
    let(:order) { create(:order, delivery_company: delivery_company) }
    let(:assignment) { create(:delivery_assignment, order: order, delivery_user: delivery_user, delivery_company: delivery_company) }

    it 'returns http success' do
      get admin_delivery_assignment_path(assignment)
      expect(response).to have_http_status(:success)
    end
  end

  describe 'GET /admin/delivery_assignments/new' do
    it 'returns http success' do
      get new_admin_delivery_assignment_path
      expect(response).to have_http_status(:success)
    end
  end

  describe 'POST /admin/delivery_assignments' do
    let(:order) { create(:order, delivery_company: delivery_company, scheduled_date: Date.current) }

    context 'with valid parameters' do
      it 'creates a new delivery assignment' do
        expect {
          post admin_delivery_assignments_path, params: {
            delivery_assignment: {
              order_id: order.id,
              delivery_user_id: delivery_user.id,
              scheduled_time: '10:00'
            }
          }
        }.to change(DeliveryAssignment, :count).by(1)
      end

      it 'redirects to the created delivery assignment' do
        post admin_delivery_assignments_path, params: {
          delivery_assignment: {
            order_id: order.id,
            delivery_user_id: delivery_user.id
          }
        }
        expect(response).to redirect_to(admin_delivery_assignment_path(DeliveryAssignment.last))
      end
    end

    context 'with invalid parameters' do
      before do
        create(:delivery_assignment, order: order, delivery_user: delivery_user, delivery_company: delivery_company)
      end

      it 'does not create a new delivery assignment' do
        expect {
          post admin_delivery_assignments_path, params: {
            delivery_assignment: {
              order_id: order.id,
              delivery_user_id: delivery_user.id
            }
          }
        }.not_to change(DeliveryAssignment, :count)
      end

      it 'renders new template with error message' do
        post admin_delivery_assignments_path, params: {
          delivery_assignment: {
            order_id: order.id,
            delivery_user_id: delivery_user.id
          }
        }
        expect(response).to have_http_status(:unprocessable_entity)
        expect(response.body).to include('既に配送割当されています')
      end
    end
  end

  describe 'GET /admin/delivery_assignments/:id/edit' do
    let(:order) { create(:order, delivery_company: delivery_company) }
    let(:assignment) { create(:delivery_assignment, order: order, delivery_user: delivery_user, delivery_company: delivery_company) }

    it 'returns http success' do
      get edit_admin_delivery_assignment_path(assignment)
      expect(response).to have_http_status(:success)
    end
  end

  describe 'PATCH /admin/delivery_assignments/:id' do
    let(:order) { create(:order, delivery_company: delivery_company) }
    let(:assignment) { create(:delivery_assignment, order: order, delivery_user: delivery_user, delivery_company: delivery_company) }
    let(:new_user) { create(:delivery_user, delivery_company: delivery_company) }

    context 'with valid parameters' do
      it 'updates the delivery assignment' do
        patch admin_delivery_assignment_path(assignment), params: {
          delivery_assignment: {
            delivery_user_id: new_user.id,
            sequence_number: 5
          }
        }
        assignment.reload
        expect(assignment.delivery_user).to eq(new_user)
        expect(assignment.sequence_number).to eq(5)
      end

      it 'redirects to the delivery assignment' do
        patch admin_delivery_assignment_path(assignment), params: {
          delivery_assignment: {
            sequence_number: 10
          }
        }
        expect(response).to redirect_to(admin_delivery_assignment_path(assignment))
      end
    end
  end

  describe 'DELETE /admin/delivery_assignments/:id' do
    let(:order) { create(:order, delivery_company: delivery_company) }
    let!(:assignment) { create(:delivery_assignment, order: order, delivery_user: delivery_user, delivery_company: delivery_company) }

    context 'with pending assignment' do
      it 'destroys the delivery assignment' do
        expect {
          delete admin_delivery_assignment_path(assignment)
        }.to change(DeliveryAssignment, :count).by(-1)
      end

      it 'redirects to the delivery assignments list' do
        delete admin_delivery_assignment_path(assignment)
        expect(response).to redirect_to(admin_delivery_assignments_path)
      end
    end

    context 'with in_transit assignment' do
      before { assignment.update!(status: 'in_transit') }

      it 'does not destroy the delivery assignment' do
        expect {
          delete admin_delivery_assignment_path(assignment)
        }.not_to change(DeliveryAssignment, :count)
      end

      it 'redirects back with an error message' do
        delete admin_delivery_assignment_path(assignment)
        expect(response).to redirect_to(admin_delivery_assignment_path(assignment))
        follow_redirect!
        expect(response.body).to include('配送中の案件はキャンセルできません')
      end
    end
  end

  describe 'POST /admin/delivery_assignments/bulk_assign' do
    let(:orders) { create_list(:order, 3, delivery_company: delivery_company, scheduled_date: Date.current) }

    it 'assigns multiple orders' do
      expect {
        post bulk_assign_admin_delivery_assignments_path, params: {
          order_ids: orders.map(&:id),
          delivery_user_id: delivery_user.id
        }
      }.to change(DeliveryAssignment, :count).by(3)
    end

    it 'redirects with success message' do
      post bulk_assign_admin_delivery_assignments_path, params: {
        order_ids: orders.map(&:id),
        delivery_user_id: delivery_user.id
      }
      expect(response).to redirect_to(admin_delivery_assignments_path)
      follow_redirect!
      expect(response.body).to include('3件の配送を割り当てました')
    end
  end
end

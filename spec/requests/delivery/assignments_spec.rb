require 'rails_helper'

RSpec.describe 'Delivery::Assignments', type: :request do
  let(:delivery_company) { create(:delivery_company) }
  let(:delivery_user) { create(:delivery_user, delivery_company: delivery_company) }
  let(:other_delivery_user) { create(:delivery_user, delivery_company: delivery_company) }
  let(:order) { create(:order, delivery_company: delivery_company, scheduled_date: Date.current) }
  let!(:delivery_assignment) do
    create(:delivery_assignment,
           order: order,
           delivery_user: delivery_user,
           delivery_company: delivery_company,
           scheduled_date: Date.current)
  end

  before do
    sign_in delivery_user
  end

  describe 'GET /delivery/assignments' do
    it 'returns http success' do
      get delivery_assignments_path
      expect(response).to have_http_status(:success)
    end

    it 'displays delivery assignments for the current user' do
      get delivery_assignments_path
      expect(response.body).to include('配送予定')
      expect(response.body).to include(order.company.name)
    end

    context 'with date filter' do
      let!(:tomorrow_assignment) do
        order2 = create(:order, delivery_company: delivery_company, scheduled_date: Date.tomorrow)
        create(:delivery_assignment,
               order: order2,
               delivery_user: delivery_user,
               delivery_company: delivery_company,
               scheduled_date: Date.tomorrow)
      end

      it 'filters by today' do
        get delivery_assignments_path, params: { filter: 'today' }
        expect(response).to have_http_status(:success)
      end

      it 'filters by week' do
        get delivery_assignments_path, params: { filter: 'week' }
        expect(response).to have_http_status(:success)
      end

      it 'filters by specific date' do
        get delivery_assignments_path, params: { date: Date.tomorrow.to_s }
        expect(response).to have_http_status(:success)
      end
    end

    context 'with status filter' do
      it 'filters by pending status' do
        get delivery_assignments_path, params: { status: 'pending' }
        expect(response).to have_http_status(:success)
      end

      it 'filters by in_transit status' do
        get delivery_assignments_path, params: { status: 'in_transit' }
        expect(response).to have_http_status(:success)
      end

      it 'filters by completed status' do
        get delivery_assignments_path, params: { status: 'completed' }
        expect(response).to have_http_status(:success)
      end
    end

    context 'when not signed in' do
      before do
        sign_out delivery_user
      end

      it 'redirects to login page' do
        get delivery_assignments_path
        expect(response).to redirect_to(new_delivery_user_session_path)
      end
    end

    context 'with inactive user' do
      let(:inactive_user) { create(:delivery_user, :inactive, delivery_company: delivery_company) }

      before do
        sign_in inactive_user
      end

      it 'redirects to login page' do
        get delivery_assignments_path
        expect(response).to redirect_to(new_delivery_user_session_path)
      end
    end
  end

  describe 'GET /delivery/assignments/:id' do
    it 'returns http success' do
      get delivery_assignment_path(delivery_assignment)
      expect(response).to have_http_status(:success)
    end

    it 'displays delivery assignment details' do
      get delivery_assignment_path(delivery_assignment)
      expect(response.body).to include('配送詳細')
      expect(response.body).to include(order.company.name)
    end

    context 'when accessing another user\'s assignment' do
      let(:other_user_assignment) do
        order2 = create(:order, delivery_company: delivery_company)
        create(:delivery_assignment,
               order: order2,
               delivery_user: other_delivery_user,
               delivery_company: delivery_company)
      end

      it 'redirects with alert' do
        get delivery_assignment_path(other_user_assignment)
        expect(response).to redirect_to(delivery_assignments_path)
        follow_redirect!
        expect(response.body).to include('配送割当が見つかりません')
      end
    end

    context 'when not signed in' do
      before do
        sign_out delivery_user
      end

      it 'redirects to login page' do
        get delivery_assignment_path(delivery_assignment)
        expect(response).to redirect_to(new_delivery_user_session_path)
      end
    end
  end

  describe 'PATCH /delivery/assignments/:id/update_status' do
    context 'from pending to preparing' do
      before do
        delivery_assignment.update(status: 'pending')
      end

      it 'updates status successfully' do
        patch update_status_delivery_assignment_path(delivery_assignment, status: 'preparing')
        expect(response).to redirect_to(delivery_assignment_path(delivery_assignment))
        follow_redirect!
        expect(response.body).to include('配送準備を開始しました')
        expect(delivery_assignment.reload.status).to eq('preparing')
      end
    end

    context 'from preparing to in_transit' do
      before do
        delivery_assignment.update(status: 'preparing')
      end

      it 'updates status successfully' do
        patch update_status_delivery_assignment_path(delivery_assignment, status: 'in_transit')
        expect(response).to redirect_to(delivery_assignment_path(delivery_assignment))
        follow_redirect!
        expect(response.body).to include('配送を開始しました')
        expect(delivery_assignment.reload.status).to eq('in_transit')
      end
    end

    context 'from in_transit to completed' do
      before do
        delivery_assignment.update(status: 'in_transit')
      end

      it 'updates status successfully' do
        patch update_status_delivery_assignment_path(delivery_assignment, status: 'completed')
        expect(response).to redirect_to(delivery_assignment_path(delivery_assignment))
        follow_redirect!
        expect(response.body).to include('配送を完了しました')
        expect(delivery_assignment.reload.status).to eq('completed')
      end
    end

    context 'marking as failed' do
      before do
        delivery_assignment.update(status: 'in_transit')
      end

      it 'marks as failed successfully' do
        patch update_status_delivery_assignment_path(delivery_assignment, status: 'failed')
        expect(response).to redirect_to(delivery_assignment_path(delivery_assignment))
        follow_redirect!
        expect(response.body).to include('配送を失敗としてマークしました')
        expect(delivery_assignment.reload.status).to eq('failed')
      end
    end

    context 'with invalid status transition' do
      before do
        delivery_assignment.update(status: 'pending')
      end

      it 'does not update status' do
        patch update_status_delivery_assignment_path(delivery_assignment, status: 'completed')
        expect(response).to redirect_to(delivery_assignment_path(delivery_assignment))
        follow_redirect!
        expect(response.body).to include('できませんでした')
        expect(delivery_assignment.reload.status).to eq('pending')
      end
    end

    context 'with invalid status value' do
      it 'shows error message' do
        patch update_status_delivery_assignment_path(delivery_assignment, status: 'invalid_status')
        expect(response).to redirect_to(delivery_assignment_path(delivery_assignment))
        follow_redirect!
        expect(response.body).to include('無効なステータスです')
      end
    end

    context 'when not signed in' do
      before do
        sign_out delivery_user
      end

      it 'redirects to login page' do
        patch update_status_delivery_assignment_path(delivery_assignment, status: 'preparing')
        expect(response).to redirect_to(new_delivery_user_session_path)
      end
    end
  end
end

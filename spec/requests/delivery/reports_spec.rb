require 'rails_helper'

RSpec.describe 'Delivery::Reports', type: :request do
  let(:delivery_company) { create(:delivery_company) }
  let(:delivery_user) { create(:delivery_user, delivery_company: delivery_company) }
  let(:order) { create(:order, delivery_company: delivery_company, scheduled_date: Date.current) }
  let(:delivery_assignment) do
    create(:delivery_assignment,
           order: order,
           delivery_user: delivery_user,
           delivery_company: delivery_company,
           status: 'in_transit')
  end

  before do
    sign_in delivery_user
  end

  describe 'GET /delivery/assignments/:assignment_id/report/new' do
    it 'returns http success' do
      get new_delivery_assignment_report_path(delivery_assignment)
      expect(response).to have_http_status(:success)
    end

    it 'displays report form' do
      get new_delivery_assignment_report_path(delivery_assignment)
      expect(response.body).to include('配送報告')
      expect(response.body).to include(order.company.name)
    end

    context 'when assignment does not belong to user' do
      let(:other_user) { create(:delivery_user, delivery_company: delivery_company) }
      let(:other_assignment) do
        order2 = create(:order, delivery_company: delivery_company)
        create(:delivery_assignment, order: order2, delivery_user: other_user, delivery_company: delivery_company)
      end

      it 'redirects with alert' do
        get new_delivery_assignment_report_path(other_assignment)
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
        get new_delivery_assignment_report_path(delivery_assignment)
        expect(response).to redirect_to(new_delivery_user_session_path)
      end
    end
  end

  describe 'POST /delivery/assignments/:assignment_id/report' do
    context 'with valid completed report params' do
      let(:report_params) do
        {
          delivery_report: {
            report_type: 'completed',
            notes: 'Delivered successfully',
            latitude: 35.6812,
            longitude: 139.7671
          }
        }
      end

      it 'creates a delivery report' do
        expect {
          post delivery_assignment_report_path(delivery_assignment), params: report_params
        }.to change(DeliveryReport, :count).by(1)
      end

      it 'updates assignment status to completed' do
        post delivery_assignment_report_path(delivery_assignment), params: report_params
        expect(delivery_assignment.reload.status).to eq('completed')
      end

      it 'redirects to assignment page with notice' do
        post delivery_assignment_report_path(delivery_assignment), params: report_params
        expect(response).to redirect_to(delivery_assignment_path(delivery_assignment))
        follow_redirect!
        expect(response.body).to include('配送報告を送信しました')
      end
    end

    context 'with issue report params' do
      let(:report_params) do
        {
          delivery_report: {
            report_type: 'issue',
            issue_type: 'absent',
            notes: 'Customer was absent'
          }
        }
      end

      it 'creates an issue report' do
        expect {
          post delivery_assignment_report_path(delivery_assignment), params: report_params
        }.to change(DeliveryReport, :count).by(1)
      end

      it 'updates assignment status to failed' do
        post delivery_assignment_report_path(delivery_assignment), params: report_params
        expect(delivery_assignment.reload.status).to eq('failed')
      end
    end

    context 'with failed report params' do
      let(:report_params) do
        {
          delivery_report: {
            report_type: 'failed',
            issue_type: 'address_unknown',
            notes: 'Could not find address'
          }
        }
      end

      it 'creates a failed report' do
        expect {
          post delivery_assignment_report_path(delivery_assignment), params: report_params
        }.to change(DeliveryReport, :count).by(1)
      end

      it 'updates assignment status to failed' do
        post delivery_assignment_report_path(delivery_assignment), params: report_params
        expect(delivery_assignment.reload.status).to eq('failed')
      end
    end

    context 'with invalid params' do
      let(:invalid_params) do
        {
          delivery_report: {
            report_type: 'invalid_type'
          }
        }
      end

      it 'does not create a delivery report' do
        expect {
          post delivery_assignment_report_path(delivery_assignment), params: invalid_params
        }.not_to change(DeliveryReport, :count)
      end

      it 'renders new template with errors' do
        post delivery_assignment_report_path(delivery_assignment), params: invalid_params
        expect(response).to have_http_status(:unprocessable_entity)
      end
    end

    context 'when assignment already has a report' do
      let!(:existing_report) do
        create(:delivery_report, delivery_assignment: delivery_assignment, delivery_user: delivery_user)
      end

      let(:report_params) do
        {
          delivery_report: {
            report_type: 'completed',
            notes: 'Second report'
          }
        }
      end

      it 'does not create a duplicate report' do
        expect {
          post delivery_assignment_report_path(delivery_assignment), params: report_params
        }.not_to change(DeliveryReport, :count)
      end
    end

    context 'when not signed in' do
      before do
        sign_out delivery_user
      end

      it 'redirects to login page' do
        post delivery_assignment_report_path(delivery_assignment), params: { delivery_report: { report_type: 'completed' } }
        expect(response).to redirect_to(new_delivery_user_session_path)
      end
    end
  end

  describe 'GET /delivery/reports/:id' do
    let!(:delivery_report) do
      create(:delivery_report, delivery_assignment: delivery_assignment, delivery_user: delivery_user)
    end

    it 'returns http success' do
      get delivery_report_path(delivery_report)
      expect(response).to have_http_status(:success)
    end

    context 'when report does not belong to user' do
      let(:other_user) { create(:delivery_user, delivery_company: delivery_company) }
      let(:other_report) do
        order2 = create(:order, delivery_company: delivery_company)
        assignment2 = create(:delivery_assignment, order: order2, delivery_user: other_user, delivery_company: delivery_company)
        create(:delivery_report, delivery_assignment: assignment2, delivery_user: other_user)
      end

      it 'redirects with alert' do
        get delivery_report_path(other_report)
        expect(response).to redirect_to(delivery_assignments_path)
        follow_redirect!
        expect(response.body).to include('配送報告が見つかりません')
      end
    end
  end
end

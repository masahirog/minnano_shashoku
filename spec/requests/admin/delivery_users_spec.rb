require 'rails_helper'

RSpec.describe 'Admin::DeliveryUsers', type: :request do
  let(:admin_user) { create(:admin_user) }
  let(:delivery_company) { create(:delivery_company) }

  before do
    sign_in admin_user
  end

  describe 'GET /admin/delivery_users' do
    it 'returns http success' do
      get admin_delivery_users_path
      expect(response).to have_http_status(:success)
    end

    it 'displays delivery users list' do
      delivery_user = create(:delivery_user, delivery_company: delivery_company)
      get admin_delivery_users_path
      expect(response.body).to include(delivery_user.name)
      expect(response.body).to include(delivery_user.email)
    end

    context 'with multiple delivery users' do
      before do
        create_list(:delivery_user, 3, delivery_company: delivery_company)
      end

      it 'displays all delivery users' do
        get admin_delivery_users_path
        expect(response.body).to include('配送担当者')
      end
    end
  end

  describe 'GET /admin/delivery_users/:id' do
    let(:delivery_user) { create(:delivery_user, delivery_company: delivery_company) }

    it 'returns http success' do
      get admin_delivery_user_path(delivery_user)
      expect(response).to have_http_status(:success)
    end

    it 'displays delivery user details' do
      get admin_delivery_user_path(delivery_user)
      expect(response.body).to include(delivery_user.name)
      expect(response.body).to include(delivery_user.email)
      expect(response.body).to include(delivery_user.phone) if delivery_user.phone.present?
    end
  end

  describe 'GET /admin/delivery_users/new' do
    it 'returns http success' do
      get new_admin_delivery_user_path
      expect(response).to have_http_status(:success)
    end

    it 'displays new delivery user form' do
      get new_admin_delivery_user_path
      expect(response.body).to include('name')
      expect(response.body).to include('email')
      expect(response.body).to include('password')
    end
  end

  describe 'POST /admin/delivery_users' do
    let(:valid_attributes) do
      {
        email: 'new_driver@example.com',
        password: 'password123',
        password_confirmation: 'password123',
        name: '新規ドライバー',
        phone: '090-1234-5678',
        role: 'driver',
        delivery_company_id: delivery_company.id,
        is_active: true
      }
    end

    context 'with valid parameters' do
      it 'creates a new delivery user' do
        expect {
          post admin_delivery_users_path, params: { delivery_user: valid_attributes }
        }.to change(DeliveryUser, :count).by(1)
      end

      it 'redirects to the created delivery user' do
        post admin_delivery_users_path, params: { delivery_user: valid_attributes }
        expect(response).to redirect_to(admin_delivery_user_path(DeliveryUser.last))
      end
    end

    context 'with invalid parameters' do
      it 'does not create a new delivery user' do
        expect {
          post admin_delivery_users_path, params: { delivery_user: valid_attributes.merge(email: '') }
        }.not_to change(DeliveryUser, :count)
      end
    end
  end

  describe 'GET /admin/delivery_users/:id/edit' do
    let(:delivery_user) { create(:delivery_user, delivery_company: delivery_company) }

    it 'returns http success' do
      get edit_admin_delivery_user_path(delivery_user)
      expect(response).to have_http_status(:success)
    end

    it 'displays edit delivery user form' do
      get edit_admin_delivery_user_path(delivery_user)
      expect(response.body).to include(delivery_user.name)
      expect(response.body).to include(delivery_user.email)
    end
  end

  describe 'PATCH /admin/delivery_users/:id' do
    let(:delivery_user) { create(:delivery_user, delivery_company: delivery_company) }
    let(:new_attributes) do
      {
        name: '更新されたドライバー',
        phone: '090-9876-5432'
      }
    end

    context 'with valid parameters' do
      it 'updates the delivery user' do
        patch admin_delivery_user_path(delivery_user), params: { delivery_user: new_attributes }
        delivery_user.reload
        expect(delivery_user.name).to eq('更新されたドライバー')
        expect(delivery_user.phone).to eq('090-9876-5432')
      end

      it 'redirects to the delivery user' do
        patch admin_delivery_user_path(delivery_user), params: { delivery_user: new_attributes }
        expect(response).to redirect_to(admin_delivery_user_path(delivery_user))
      end
    end

    context 'with password change' do
      it 'updates the password when provided' do
        patch admin_delivery_user_path(delivery_user), params: {
          delivery_user: {
            password: 'newpassword123',
            password_confirmation: 'newpassword123'
          }
        }
        delivery_user.reload
        expect(delivery_user.valid_password?('newpassword123')).to be true
      end

      it 'does not change password when blank' do
        old_encrypted_password = delivery_user.encrypted_password
        patch admin_delivery_user_path(delivery_user), params: {
          delivery_user: {
            name: '更新',
            password: '',
            password_confirmation: ''
          }
        }
        delivery_user.reload
        expect(delivery_user.encrypted_password).to eq(old_encrypted_password)
      end
    end

    context 'with invalid parameters' do
      it 'does not update the delivery user' do
        original_name = delivery_user.name
        patch admin_delivery_user_path(delivery_user), params: { delivery_user: { email: '' } }
        delivery_user.reload
        expect(delivery_user.name).to eq(original_name)
      end
    end
  end

  describe 'DELETE /admin/delivery_users/:id' do
    let!(:delivery_user) { create(:delivery_user, delivery_company: delivery_company) }

    context 'without delivery assignments' do
      it 'destroys the delivery user' do
        expect {
          delete admin_delivery_user_path(delivery_user)
        }.to change(DeliveryUser, :count).by(-1)
      end

      it 'redirects to the delivery users list' do
        delete admin_delivery_user_path(delivery_user)
        expect(response).to redirect_to(admin_delivery_users_path)
      end
    end

    context 'with delivery assignments' do
      before do
        create(:delivery_assignment, delivery_user: delivery_user, delivery_company: delivery_company)
      end

      it 'does not destroy the delivery user' do
        expect {
          delete admin_delivery_user_path(delivery_user)
        }.not_to change(DeliveryUser, :count)
      end

      it 'redirects back with an error message' do
        delete admin_delivery_user_path(delivery_user)
        expect(response).to redirect_to(admin_delivery_user_path(delivery_user))
        follow_redirect!
        expect(response.body).to include('配送割当が存在するため、削除できません')
      end
    end
  end
end

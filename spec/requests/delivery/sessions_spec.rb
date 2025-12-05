require 'rails_helper'

RSpec.describe 'Delivery::Sessions', type: :request do
  let(:delivery_company) { create(:delivery_company) }
  let(:delivery_user) { create(:delivery_user, delivery_company: delivery_company) }

  describe 'GET /delivery/login' do
    it 'returns http success' do
      get new_delivery_user_session_path
      expect(response).to have_http_status(:success)
    end

    it 'displays the login form' do
      get new_delivery_user_session_path
      expect(response.body).to include('ログイン')
      expect(response.body).to include('メールアドレス')
      expect(response.body).to include('パスワード')
    end
  end

  describe 'POST /delivery/login' do
    context 'with valid credentials' do
      it 'logs in the user and redirects to dashboard' do
        post delivery_user_session_path, params: {
          delivery_user: {
            email: delivery_user.email,
            password: 'password123'
          }
        }
        expect(response).to redirect_to(delivery_root_path)
        follow_redirect!
        expect(response.body).to include(delivery_user.name)
      end

      it 'updates sign_in_count' do
        expect {
          post delivery_user_session_path, params: {
            delivery_user: {
              email: delivery_user.email,
              password: 'password123'
            }
          }
        }.to change { delivery_user.reload.sign_in_count }.by(1)
      end
    end

    context 'with invalid credentials' do
      it 'does not log in the user' do
        post delivery_user_session_path, params: {
          delivery_user: {
            email: delivery_user.email,
            password: 'wrongpassword'
          }
        }
        expect(response).to have_http_status(:unprocessable_entity)
      end
    end

    context 'with inactive user' do
      let(:inactive_user) { create(:delivery_user, :inactive, delivery_company: delivery_company) }

      it 'does not log in the user' do
        post delivery_user_session_path, params: {
          delivery_user: {
            email: inactive_user.email,
            password: 'password123'
          }
        }
        expect(response).to redirect_to(new_delivery_user_session_path)
        follow_redirect!
        expect(response.body).to include('アカウントが無効化されています')
      end
    end
  end

  describe 'DELETE /delivery/logout' do
    before do
      sign_in delivery_user
    end

    it 'logs out the user and redirects to login page' do
      delete destroy_delivery_user_session_path
      expect(response).to redirect_to(new_delivery_user_session_path)
    end
  end
end

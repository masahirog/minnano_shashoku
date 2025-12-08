require 'rails_helper'

RSpec.describe "Admin::SupplyForecasts", type: :request do
  describe "GET /index" do
    it "returns http success" do
      get "/admin/supply_forecasts/index"
      expect(response).to have_http_status(:success)
    end
  end

  describe "GET /show" do
    it "returns http success" do
      get "/admin/supply_forecasts/show"
      expect(response).to have_http_status(:success)
    end
  end

end

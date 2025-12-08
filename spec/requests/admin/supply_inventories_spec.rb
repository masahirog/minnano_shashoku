require 'rails_helper'

RSpec.describe "Admin::SupplyInventories", type: :request do
  describe "GET /index" do
    it "returns http success" do
      get "/admin/supply_inventories/index"
      expect(response).to have_http_status(:success)
    end
  end

  describe "GET /new" do
    it "returns http success" do
      get "/admin/supply_inventories/new"
      expect(response).to have_http_status(:success)
    end
  end

  describe "GET /create" do
    it "returns http success" do
      get "/admin/supply_inventories/create"
      expect(response).to have_http_status(:success)
    end
  end

  describe "GET /show" do
    it "returns http success" do
      get "/admin/supply_inventories/show"
      expect(response).to have_http_status(:success)
    end
  end

end

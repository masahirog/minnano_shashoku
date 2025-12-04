require 'rails_helper'

RSpec.describe LowStockChecker do
  let(:checker) { LowStockChecker.new }
  let(:company) { Company.create!(name: '企業A', formal_name: '株式会社企業A', contract_status: 'active') }

  before do
    # メール送信をモック
    allow(SupplyMailer).to receive(:low_stock_alert).and_return(double(deliver_now: true))
    allow(SupplyMailer).to receive(:out_of_stock_alert).and_return(double(deliver_now: true))
  end

  describe '#check_low_stock' do
    it '在庫が再注文ポイント以下の備品を検出する' do
      # 在庫不足（total_stock: 5, reorder_point: 10）
      supply1 = Supply.create!(
        name: 'プラスチック容器',
        sku: 'CONT-001',
        category: '使い捨て備品',
        unit: '個',
        reorder_point: 10,
        is_active: true
      )
      SupplyStock.create!(supply: supply1, quantity: 5, location_name: '本社')

      # 在庫十分（total_stock: 20, reorder_point: 10）
      supply2 = Supply.create!(
        name: '割り箸',
        sku: 'DISP-002',
        category: '使い捨て備品',
        unit: '膳',
        reorder_point: 10,
        is_active: true
      )
      SupplyStock.create!(supply: supply2, quantity: 20, location_name: '本社')

      # 在庫不足（total_stock: 3, reorder_point: 5）
      supply3 = Supply.create!(
        name: '紙ナプキン',
        sku: 'DISP-003',
        category: '使い捨て備品',
        unit: 'パック',
        reorder_point: 5,
        is_active: true
      )
      SupplyStock.create!(supply: supply3, quantity: 3, location_name: '本社')

      low_stock_supplies = checker.check_low_stock

      expect(low_stock_supplies.count).to eq(2)
      expect(low_stock_supplies.map(&:name)).to match_array(['プラスチック容器', '紙ナプキン'])
    end

    it '在庫切れの備品は在庫不足に含まない' do
      # 在庫切れ（total_stock: 0, reorder_point: 10）
      supply1 = Supply.create!(
        name: 'プラスチック容器',
        sku: 'CONT-001',
        category: '使い捨て備品',
        unit: '個',
        reorder_point: 10,
        is_active: true
      )
      SupplyStock.create!(supply: supply1, quantity: 0, location_name: '本社')

      low_stock_supplies = checker.check_low_stock

      expect(low_stock_supplies.count).to eq(0)
    end

    it '非アクティブな備品は検出されない' do
      # 在庫不足だがis_active: false
      supply1 = Supply.create!(
        name: 'プラスチック容器',
        sku: 'CONT-001',
        category: '使い捨て備品',
        unit: '個',
        reorder_point: 10,
        is_active: false
      )
      SupplyStock.create!(supply: supply1, quantity: 5, location_name: '本社')

      low_stock_supplies = checker.check_low_stock

      expect(low_stock_supplies.count).to eq(0)
    end

    it '再注文ポイントが設定されていない備品は検出されない' do
      supply1 = Supply.create!(
        name: 'プラスチック容器',
        sku: 'CONT-001',
        category: '使い捨て備品',
        unit: '個',
        reorder_point: nil,
        is_active: true
      )
      SupplyStock.create!(supply: supply1, quantity: 5, location_name: '本社')

      low_stock_supplies = checker.check_low_stock

      expect(low_stock_supplies.count).to eq(0)
    end
  end

  describe '#check_out_of_stock' do
    it '在庫がゼロの備品を検出する' do
      # 在庫切れ
      supply1 = Supply.create!(
        name: 'プラスチック容器',
        sku: 'CONT-001',
        category: '使い捨て備品',
        unit: '個',
        reorder_point: 10,
        is_active: true
      )
      SupplyStock.create!(supply: supply1, quantity: 0, location_name: '本社')

      # 在庫あり
      supply2 = Supply.create!(
        name: '割り箸',
        sku: 'DISP-002',
        category: '使い捨て備品',
        unit: '膳',
        reorder_point: 10,
        is_active: true
      )
      SupplyStock.create!(supply: supply2, quantity: 5, location_name: '本社')

      # 在庫切れ
      supply3 = Supply.create!(
        name: '紙ナプキン',
        sku: 'DISP-003',
        category: '使い捨て備品',
        unit: 'パック',
        reorder_point: 5,
        is_active: true
      )
      SupplyStock.create!(supply: supply3, quantity: 0, location_name: '本社')

      out_of_stock_supplies = checker.check_out_of_stock

      expect(out_of_stock_supplies.count).to eq(2)
      expect(out_of_stock_supplies.map(&:name)).to match_array(['プラスチック容器', '紙ナプキン'])
    end

    it '非アクティブな備品は検出されない' do
      supply1 = Supply.create!(
        name: 'プラスチック容器',
        sku: 'CONT-001',
        category: '使い捨て備品',
        unit: '個',
        reorder_point: 10,
        is_active: false
      )
      SupplyStock.create!(supply: supply1, quantity: 0, location_name: '本社')

      out_of_stock_supplies = checker.check_out_of_stock

      expect(out_of_stock_supplies.count).to eq(0)
    end

    it '複数拠点の在庫を合算してゼロの場合、検出される' do
      supply1 = Supply.create!(
        name: 'プラスチック容器',
        sku: 'CONT-001',
        category: '使い捨て備品',
        unit: '個',
        reorder_point: 10,
        is_active: true
      )
      SupplyStock.create!(supply: supply1, quantity: 0, location_name: '本社')
      SupplyStock.create!(supply: supply1, quantity: 0, location_type: 'Company', location_id: company.id)

      out_of_stock_supplies = checker.check_out_of_stock

      expect(out_of_stock_supplies.count).to eq(1)
      expect(out_of_stock_supplies.first.total_stock).to eq(0)
    end
  end

  describe '#check_all' do
    it '在庫不足と在庫切れの両方をチェックする' do
      # 在庫不足
      supply1 = Supply.create!(
        name: 'プラスチック容器',
        sku: 'CONT-001',
        category: '使い捨て備品',
        unit: '個',
        reorder_point: 10,
        is_active: true
      )
      SupplyStock.create!(supply: supply1, quantity: 5, location_name: '本社')

      # 在庫切れ
      supply2 = Supply.create!(
        name: '割り箸',
        sku: 'DISP-002',
        category: '使い捨て備品',
        unit: '膳',
        reorder_point: 10,
        is_active: true
      )
      SupplyStock.create!(supply: supply2, quantity: 0, location_name: '本社')

      # 在庫十分
      supply3 = Supply.create!(
        name: '紙ナプキン',
        sku: 'DISP-003',
        category: '使い捨て備品',
        unit: 'パック',
        reorder_point: 5,
        is_active: true
      )
      SupplyStock.create!(supply: supply3, quantity: 20, location_name: '本社')

      result = checker.check_all

      expect(result[:low_stock_count]).to eq(1)
      expect(result[:out_of_stock_count]).to eq(1)
      expect(result[:total_alerts]).to eq(2)
      expect(result[:low_stock_supplies].map(&:name)).to eq(['プラスチック容器'])
      expect(result[:out_of_stock_supplies].map(&:name)).to eq(['割り箸'])
    end

    it 'アラートがない場合、すべてのカウントがゼロ' do
      # 在庫十分
      supply1 = Supply.create!(
        name: 'プラスチック容器',
        sku: 'CONT-001',
        category: '使い捨て備品',
        unit: '個',
        reorder_point: 10,
        is_active: true
      )
      SupplyStock.create!(supply: supply1, quantity: 20, location_name: '本社')

      result = checker.check_all

      expect(result[:low_stock_count]).to eq(0)
      expect(result[:out_of_stock_count]).to eq(0)
      expect(result[:total_alerts]).to eq(0)
    end
  end

  describe '#send_low_stock_alerts' do
    it '在庫不足アラートメールを送信する' do
      supply1 = Supply.create!(
        name: 'プラスチック容器',
        sku: 'CONT-001',
        category: '使い捨て備品',
        unit: '個',
        reorder_point: 10,
        is_active: true
      )
      SupplyStock.create!(supply: supply1, quantity: 5, location_name: '本社')

      checker.check_low_stock

      expect(SupplyMailer).to receive(:low_stock_alert)
        .with(checker.low_stock_supplies, 'test@example.com')
        .and_call_original

      sent_count = checker.send_low_stock_alerts(recipient_email: 'test@example.com')

      expect(sent_count).to eq(1)
    end

    it '在庫不足がない場合、メールを送信しない' do
      supply1 = Supply.create!(
        name: 'プラスチック容器',
        sku: 'CONT-001',
        category: '使い捨て備品',
        unit: '個',
        reorder_point: 10,
        is_active: true
      )
      SupplyStock.create!(supply: supply1, quantity: 20, location_name: '本社')

      checker.check_low_stock

      expect(SupplyMailer).not_to receive(:low_stock_alert)

      sent_count = checker.send_low_stock_alerts(recipient_email: 'test@example.com')

      expect(sent_count).to eq(0)
    end
  end

  describe '#send_out_of_stock_alerts' do
    it '在庫切れアラートメールを送信する' do
      supply1 = Supply.create!(
        name: 'プラスチック容器',
        sku: 'CONT-001',
        category: '使い捨て備品',
        unit: '個',
        reorder_point: 10,
        is_active: true
      )
      SupplyStock.create!(supply: supply1, quantity: 0, location_name: '本社')

      checker.check_out_of_stock

      expect(SupplyMailer).to receive(:out_of_stock_alert)
        .with(checker.out_of_stock_supplies, 'test@example.com')
        .and_call_original

      sent_count = checker.send_out_of_stock_alerts(recipient_email: 'test@example.com')

      expect(sent_count).to eq(1)
    end

    it '在庫切れがない場合、メールを送信しない' do
      supply1 = Supply.create!(
        name: 'プラスチック容器',
        sku: 'CONT-001',
        category: '使い捨て備品',
        unit: '個',
        reorder_point: 10,
        is_active: true
      )
      SupplyStock.create!(supply: supply1, quantity: 5, location_name: '本社')

      checker.check_out_of_stock

      expect(SupplyMailer).not_to receive(:out_of_stock_alert)

      sent_count = checker.send_out_of_stock_alerts(recipient_email: 'test@example.com')

      expect(sent_count).to eq(0)
    end
  end

  describe '#send_all_alerts' do
    it '在庫不足と在庫切れの両方のアラートメールを送信する' do
      # 在庫不足
      supply1 = Supply.create!(
        name: 'プラスチック容器',
        sku: 'CONT-001',
        category: '使い捨て備品',
        unit: '個',
        reorder_point: 10,
        is_active: true
      )
      SupplyStock.create!(supply: supply1, quantity: 5, location_name: '本社')

      # 在庫切れ
      supply2 = Supply.create!(
        name: '割り箸',
        sku: 'DISP-002',
        category: '使い捨て備品',
        unit: '膳',
        reorder_point: 10,
        is_active: true
      )
      SupplyStock.create!(supply: supply2, quantity: 0, location_name: '本社')

      checker.check_all

      result = checker.send_all_alerts(recipient_email: 'test@example.com')

      expect(result[:low_stock_sent]).to eq(1)
      expect(result[:out_of_stock_sent]).to eq(1)
      expect(result[:total_sent]).to eq(2)
    end
  end

  describe '#summary' do
    it '在庫状況のサマリーを返す' do
      # 在庫不足
      supply1 = Supply.create!(
        name: 'プラスチック容器',
        sku: 'CONT-001',
        category: '使い捨て備品',
        unit: '個',
        reorder_point: 10,
        is_active: true
      )
      SupplyStock.create!(supply: supply1, quantity: 5, location_name: '本社')

      # 在庫切れ
      supply2 = Supply.create!(
        name: '割り箸',
        sku: 'DISP-002',
        category: '使い捨て備品',
        unit: '膳',
        reorder_point: 10,
        is_active: true
      )
      SupplyStock.create!(supply: supply2, quantity: 0, location_name: '本社')

      # 在庫十分
      supply3 = Supply.create!(
        name: '紙ナプキン',
        sku: 'DISP-003',
        category: '使い捨て備品',
        unit: 'パック',
        reorder_point: 5,
        is_active: true
      )
      SupplyStock.create!(supply: supply3, quantity: 20, location_name: '本社')

      checker.check_all
      summary = checker.summary

      expect(summary[:total_supplies]).to eq(3)
      expect(summary[:low_stock_count]).to eq(1)
      expect(summary[:out_of_stock_count]).to eq(1)
      expect(summary[:healthy_stock_count]).to eq(1)
    end
  end
end

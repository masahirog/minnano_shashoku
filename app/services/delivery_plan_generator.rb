# DeliveryPlan自動生成サービス
#
# 指定日のOrdersから配送計画を自動生成します。
# - 配送会社ごとにDeliveryPlanを作成
# - Ordersを効率的な順序で配置
# - 各Orderに対して4つのアクション（pickup, delivery, collection, return）を生成
#
class DeliveryPlanGenerator
  attr_reader :date, :delivery_company_id, :errors

  def initialize(date:, delivery_company_id: nil)
    @date = date
    @delivery_company_id = delivery_company_id
    @errors = []
  end

  # 配送計画を自動生成
  # @return [Hash] { success: Boolean, plans: Array<DeliveryPlan>, count: Integer, errors: Array<String> }
  def generate
    result = {
      success: false,
      plans: [],
      count: 0,
      errors: []
    }

    begin
      # 対象のOrdersを取得
      orders = fetch_target_orders

      if orders.empty?
        @errors << "#{@date.strftime('%Y年%m月%d日')}に生成可能なOrderがありません"
        result[:errors] = @errors
        return result
      end

      # 配送会社ごとにグループ化
      grouped_orders = group_orders_by_delivery_company(orders)

      # 各配送会社ごとにDeliveryPlanを作成
      ActiveRecord::Base.transaction do
        grouped_orders.each do |delivery_company, company_orders|
          plan = create_delivery_plan_for_company(delivery_company, company_orders)

          if plan.persisted?
            result[:plans] << plan
            result[:count] += 1
          else
            @errors << "配送会社「#{delivery_company.name}」のプラン作成に失敗: #{plan.errors.full_messages.join(', ')}"
          end
        end

        if @errors.any?
          raise ActiveRecord::Rollback
        end
      end

      result[:success] = @errors.empty?
      result[:errors] = @errors

    rescue StandardError => e
      @errors << "予期しないエラー: #{e.message}"
      result[:errors] = @errors
    end

    result
  end

  private

  # 対象のOrdersを取得
  def fetch_target_orders
    orders = Order.includes(:company, :restaurant, :delivery_company, :menus)
                  .where(scheduled_date: @date)
                  .where(status: '確定') # 確定済みのOrderのみ
                  .where.not(delivery_company_id: nil) # 配送会社が設定されているもの

    # 配送会社が指定されている場合はフィルタリング
    orders = orders.where(delivery_company_id: @delivery_company_id) if @delivery_company_id.present?

    # 既にDeliveryPlanに割り当てられているOrdersを除外
    orders = orders.left_joins(:delivery_plan_item_orders)
                   .where(delivery_plan_item_orders: { id: nil })

    # collection_time順でソート（時間が早い順）
    orders.order(Arel.sql('COALESCE(collection_time, time \'23:59\')'))
  end

  # 配送会社ごとにOrdersをグループ化
  def group_orders_by_delivery_company(orders)
    orders.group_by(&:delivery_company)
  end

  # 配送会社に対してDeliveryPlanを作成
  def create_delivery_plan_for_company(delivery_company, orders)
    # DeliveryPlanを作成
    plan = DeliveryPlan.create(
      delivery_company: delivery_company,
      delivery_date: @date,
      status: 'draft',
      notes: "自動生成 - #{orders.count}件のOrder"
    )

    return plan unless plan.persisted?

    # Ordersを最適な順序で配置
    sorted_orders = optimize_order_sequence(orders)

    # 各Orderに対してDeliveryPlanItemsを自動生成
    plan.auto_generate_items_from_orders(sorted_orders.map(&:id))

    plan
  end

  # Ordersの配置順序を最適化
  # 現在は簡易実装: collection_time順
  # 将来的には地理的最適化を実装可能
  def optimize_order_sequence(orders)
    # collection_timeが設定されているものを優先
    orders.sort_by do |order|
      [
        order.collection_time ? 0 : 1, # collection_timeがあるものを優先
        order.collection_time || Time.zone.parse('23:59'), # 時間順
        order.id # 同じ時間の場合はID順
      ]
    end
  end
end

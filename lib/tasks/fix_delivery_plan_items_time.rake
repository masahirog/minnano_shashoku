namespace :delivery_plan_items do
  desc "scheduled_timeがnilのDeliveryPlanItemsにデフォルト時刻を設定"
  task fix_scheduled_time: :environment do
    puts "scheduled_timeがnilのDeliveryPlanItemsを検索中..."

    items_without_time = DeliveryPlanItem.where(scheduled_time: nil).includes(:order)

    if items_without_time.empty?
      puts "✅ scheduled_timeがnilのアイテムはありません"
      exit
    end

    puts "#{items_without_time.count}件のアイテムが見つかりました"
    puts ""

    # アクションタイプごとのデフォルト時刻
    default_times = {
      'pickup' => '10:00',
      'delivery' => '11:00',
      'collection' => '13:00',
      'return' => '15:00',
      'supply_pickup' => '09:00',
      'supply_return' => '16:00'
    }

    updated_count = 0
    failed_count = 0

    items_without_time.find_each do |item|
      order = item.order

      unless order&.scheduled_date
        puts "⚠️  DeliveryPlanItem ##{item.id}: Orderまたはscheduled_dateがありません"
        failed_count += 1
        next
      end

      default_time = default_times[item.action_type] || '12:00'
      scheduled_time = Time.zone.parse("#{order.scheduled_date} #{default_time}")

      if item.update(scheduled_time: scheduled_time)
        puts "✅ DeliveryPlanItem ##{item.id} (Order ##{order.id}, #{item.action_type}): #{scheduled_time.strftime('%Y-%m-%d %H:%M')}"
        updated_count += 1
      else
        puts "❌ DeliveryPlanItem ##{item.id}: 更新失敗 - #{item.errors.full_messages.join(', ')}"
        failed_count += 1
      end
    end

    puts ""
    puts "完了: #{updated_count}件更新, #{failed_count}件失敗"
  end
end

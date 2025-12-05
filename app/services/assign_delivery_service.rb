class AssignDeliveryService
  class AssignmentError < StandardError; end

  def initialize(delivery_company_id: nil)
    @delivery_company_id = delivery_company_id
  end

  # 単一の案件を配送担当者に割り当て
  def assign(order_id, delivery_user_id, options = {})
    order = Order.find(order_id)
    delivery_user = DeliveryUser.find(delivery_user_id)

    # バリデーション
    validate_assignment!(order, delivery_user)

    # 既存の割当をチェック
    if order.delivery_assignment.present?
      raise AssignmentError, "この案件は既に配送割当されています"
    end

    # 配送順序を自動設定
    sequence_number = options[:sequence_number] || calculate_next_sequence(delivery_user, order.scheduled_date)

    # 割当作成
    assignment = DeliveryAssignment.create!(
      order: order,
      delivery_user: delivery_user,
      delivery_company: delivery_user.delivery_company,
      scheduled_date: order.scheduled_date,
      scheduled_time: options[:scheduled_time],
      sequence_number: sequence_number,
      status: 'pending',
      assigned_at: Time.current
    )

    # TODO: プッシュ通知送信（Phase 3 Week 7で実装予定）
    # send_assignment_notification(assignment)

    assignment
  end

  # 複数の案件を一括で配送担当者に割り当て
  def bulk_assign(order_ids, delivery_user_id, options = {})
    delivery_user = DeliveryUser.find(delivery_user_id)
    orders = Order.where(id: order_ids).order(:scheduled_date, :id)

    assignments = []
    errors = []

    orders.each do |order|
      begin
        assignment = assign(order.id, delivery_user_id, options)
        assignments << assignment
      rescue => e
        errors << { order_id: order.id, error: e.message }
      end
    end

    {
      success: assignments,
      errors: errors,
      total: order_ids.size,
      assigned: assignments.size,
      failed: errors.size
    }
  end

  # 配送割当を再割当（担当者変更）
  def reassign(assignment_id, new_delivery_user_id, options = {})
    assignment = DeliveryAssignment.find(assignment_id)
    new_delivery_user = DeliveryUser.find(new_delivery_user_id)

    # 進行中の配送は再割当できない
    if assignment.status == 'in_transit'
      raise AssignmentError, "配送中の案件は再割当できません"
    end

    # 完了した配送は再割当できない
    if assignment.status == 'completed'
      raise AssignmentError, "完了した配送は再割当できません"
    end

    assignment.update!(
      delivery_user: new_delivery_user,
      delivery_company: new_delivery_user.delivery_company,
      sequence_number: options[:sequence_number] || assignment.sequence_number,
      assigned_at: Time.current
    )

    assignment
  end

  # 配送割当をキャンセル
  def cancel(assignment_id)
    assignment = DeliveryAssignment.find(assignment_id)

    # 進行中または完了した配送はキャンセルできない
    if assignment.status == 'in_transit'
      raise AssignmentError, "配送中の案件はキャンセルできません"
    end

    if assignment.status == 'completed'
      raise AssignmentError, "完了した配送はキャンセルできません"
    end

    assignment.destroy!
  end

  private

  def validate_assignment!(order, delivery_user)
    # 配送担当者がアクティブか確認
    unless delivery_user.is_active?
      raise AssignmentError, "無効な配送担当者です"
    end

    # 案件に配送会社が設定されているか確認
    unless order.delivery_company_id.present?
      raise AssignmentError, "案件に配送会社が設定されていません"
    end

    # 配送担当者の会社と案件の配送会社が一致するか確認
    unless delivery_user.delivery_company_id == order.delivery_company_id
      raise AssignmentError, "配送担当者の所属会社と案件の配送会社が一致しません"
    end
  end

  def calculate_next_sequence(delivery_user, scheduled_date)
    # 同じ日付の配送担当者の最大sequence_numberを取得
    max_sequence = DeliveryAssignment
      .where(delivery_user: delivery_user, scheduled_date: scheduled_date)
      .maximum(:sequence_number) || 0

    max_sequence + 1
  end

  # TODO: Phase 3 Week 7で実装予定
  # def send_assignment_notification(assignment)
  #   PushNotificationService.new.send_to_delivery_user(
  #     assignment.delivery_user,
  #     title: "新規配送依頼",
  #     body: "#{assignment.order.company.name}への配送が割り当てられました",
  #     data: { assignment_id: assignment.id }
  #   )
  # end
end

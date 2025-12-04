class LowStockChecker
  attr_reader :low_stock_supplies, :out_of_stock_supplies

  def initialize
    @low_stock_supplies = []
    @out_of_stock_supplies = []
  end

  # すべての在庫をチェック
  def check_all
    check_low_stock
    check_out_of_stock

    {
      low_stock_count: @low_stock_supplies.count,
      low_stock_supplies: @low_stock_supplies,
      out_of_stock_count: @out_of_stock_supplies.count,
      out_of_stock_supplies: @out_of_stock_supplies,
      total_alerts: @low_stock_supplies.count + @out_of_stock_supplies.count
    }
  end

  # 在庫不足をチェック
  def check_low_stock
    @low_stock_supplies = Supply.where(is_active: true)
                                .select { |supply| supply.needs_reorder? && supply.total_stock > 0 }
    @low_stock_supplies
  end

  # 在庫切れをチェック
  def check_out_of_stock
    @out_of_stock_supplies = Supply.where(is_active: true)
                                   .select { |supply| supply.total_stock == 0 }
    @out_of_stock_supplies
  end

  # 在庫不足アラートメールを送信
  def send_low_stock_alerts(recipient_email: nil)
    return 0 if @low_stock_supplies.empty?

    # 管理者のメールアドレスを取得（デフォルトは環境変数またはシステム管理者）
    recipients = recipient_email ? [recipient_email] : default_recipients

    sent_count = 0
    recipients.each do |email|
      begin
        SupplyMailer.low_stock_alert(@low_stock_supplies, email).deliver_now
        sent_count += 1
      rescue StandardError => e
        Rails.logger.error "Failed to send low stock alert to #{email}: #{e.message}"
      end
    end

    sent_count
  end

  # 在庫切れアラートメールを送信
  def send_out_of_stock_alerts(recipient_email: nil)
    return 0 if @out_of_stock_supplies.empty?

    recipients = recipient_email ? [recipient_email] : default_recipients

    sent_count = 0
    recipients.each do |email|
      begin
        SupplyMailer.out_of_stock_alert(@out_of_stock_supplies, email).deliver_now
        sent_count += 1
      rescue StandardError => e
        Rails.logger.error "Failed to send out of stock alert to #{email}: #{e.message}"
      end
    end

    sent_count
  end

  # すべてのアラートメールを一括送信
  def send_all_alerts(recipient_email: nil)
    low_stock_sent = send_low_stock_alerts(recipient_email: recipient_email)
    out_of_stock_sent = send_out_of_stock_alerts(recipient_email: recipient_email)

    {
      low_stock_sent: low_stock_sent,
      out_of_stock_sent: out_of_stock_sent,
      total_sent: low_stock_sent + out_of_stock_sent
    }
  end

  # 在庫状況のサマリーを取得
  def summary
    {
      total_supplies: Supply.where(is_active: true).count,
      low_stock_count: @low_stock_supplies.count,
      out_of_stock_count: @out_of_stock_supplies.count,
      healthy_stock_count: Supply.where(is_active: true).count - @low_stock_supplies.count - @out_of_stock_supplies.count
    }
  end

  private

  def default_recipients
    # AdminUserから通知を受け取るユーザーのメールアドレスを取得
    # 実装例: AdminUser.where(receive_notifications: true).pluck(:email)
    # とりあえずシステム管理者メールアドレスを返す
    admin_emails = AdminUser.where(email: ['admin@example.com']).pluck(:email)
    admin_emails.presence || ['admin@example.com']
  end
end

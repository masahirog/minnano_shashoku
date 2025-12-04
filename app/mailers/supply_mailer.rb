class SupplyMailer < ApplicationMailer
  default from: 'noreply@minnano-shashoku.com'

  # 在庫不足アラートメール
  def low_stock_alert(supplies, recipient_email)
    @supplies = supplies
    @alert_date = Date.today

    mail(
      to: recipient_email,
      subject: "【在庫アラート】在庫不足の備品があります (#{@supplies.count}件)"
    )
  end

  # 在庫切れアラートメール
  def out_of_stock_alert(supplies, recipient_email)
    @supplies = supplies
    @alert_date = Date.today

    mail(
      to: recipient_email,
      subject: "【緊急】在庫切れの備品があります (#{@supplies.count}件)"
    )
  end
end

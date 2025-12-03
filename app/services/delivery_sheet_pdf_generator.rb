class DeliverySheetPdfGenerator
  def initialize(orders, start_date: nil, end_date: nil)
    @orders = orders
    @start_date = start_date || orders.minimum(:scheduled_date)
    @end_date = end_date || orders.maximum(:scheduled_date)
  end

  def generate
    Prawn::Document.new(page_size: 'A4', page_layout: :landscape, margin: [20, 20, 20, 20]) do |pdf|
      # 日本語フォントを設定（フォントファイルがある場合）
      font_path = Rails.root.join('app', 'assets', 'fonts', 'NotoSansJP-Regular.ttf')
      if File.exist?(font_path)
        pdf.font_families.update('NotoSansJP' => { normal: font_path.to_s })
        pdf.font 'NotoSansJP'
      end

      # タイトル
      pdf.text "配送シート", size: 20, style: :bold, align: :center
      pdf.move_down 5
      pdf.text "期間: #{@start_date.strftime('%Y年%m月%d日')} 〜 #{@end_date.strftime('%Y年%m月%d日')}",
               size: 12, align: :center
      pdf.move_down 20

      # 日付ごとにグループ化
      @orders.group_by(&:scheduled_date).sort.each do |date, daily_orders|
        generate_daily_sheet(pdf, date, daily_orders)
        pdf.start_new_page unless date == @orders.last.scheduled_date
      end
    end.render
  end

  private

  def generate_daily_sheet(pdf, date, orders)
    # 日付ヘッダー
    pdf.text "#{date.strftime('%Y年%m月%d日')} (#{%w[日 月 火 水 木 金 土][date.wday]}曜日)",
             size: 16, style: :bold
    pdf.move_down 10

    # テーブルデータ作成
    table_data = [table_headers]

    orders.sort_by { |o| o.collection_time || Time.parse('00:00') }.each do |order|
      table_data << [
        order.collection_time&.strftime('%H:%M') || '-',
        order.warehouse_pickup_time&.strftime('%H:%M') || '-',
        order.company&.name || '-',
        order.restaurant&.name || '-',
        order.menu&.name || '-',
        order.default_meal_count.to_s,
        order.is_trial ? '試食会' : '本導入',
        order.return_location || '-',
        order.equipment_notes || '-'
      ]
    end

    # テーブル描画
    pdf.table(table_data,
              header: true,
              width: pdf.bounds.width,
              cell_style: {
                size: 9,
                padding: [4, 6],
                borders: [:top, :bottom, :left, :right],
                border_width: 0.5
              },
              column_widths: column_widths(pdf.bounds.width)) do |table|
      # ヘッダー行のスタイル
      table.row(0).font_style = :bold
      table.row(0).background_color = 'CCCCCC'
      table.row(0).align = :center
    end

    pdf.move_down 20
  end

  def table_headers
    [
      '回収時刻',
      '倉庫集荷',
      '企業名',
      '飲食店名',
      'メニュー',
      '食数',
      '区分',
      '返却先',
      '器材メモ'
    ]
  end

  def column_widths(total_width)
    {
      0 => total_width * 0.08,  # 回収時刻
      1 => total_width * 0.08,  # 倉庫集荷
      2 => total_width * 0.12,  # 企業名
      3 => total_width * 0.15,  # 飲食店名
      4 => total_width * 0.15,  # メニュー
      5 => total_width * 0.06,  # 食数
      6 => total_width * 0.08,  # 区分
      7 => total_width * 0.10,  # 返却先
      8 => total_width * 0.18   # 器材メモ
    }
  end
end

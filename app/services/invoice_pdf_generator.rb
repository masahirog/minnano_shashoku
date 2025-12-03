class InvoicePdfGenerator
  def initialize(invoice)
    @invoice = invoice
    @company = invoice.company
  end

  def generate
    Prawn::Document.new(page_size: 'A4', page_layout: :portrait, margin: [40, 40, 40, 40]) do |pdf|
      # 日本語フォント設定
      font_path = Rails.root.join('app', 'assets', 'fonts', 'NotoSansJP-Regular.ttf')
      if File.exist?(font_path)
        pdf.font_families.update('NotoSansJP' => { normal: font_path.to_s })
        pdf.font 'NotoSansJP'
      end

      # タイトル
      pdf.text "請求書", size: 24, align: :center
      pdf.move_down 30

      # 請求書情報と請求先情報を横並び
      pdf.bounding_box([0, pdf.cursor], width: 520, height: 100) do
        # 左側：請求先情報
        pdf.bounding_box([0, pdf.cursor], width: 260) do
          pdf.text @company.formal_name, size: 14
          pdf.move_down 5
          if @company.delivery_address.present?
            pdf.text @company.delivery_address, size: 10
            pdf.move_down 3
          end
          if @company.contact_person.present?
            pdf.text "ご担当者: #{@company.contact_person} 様", size: 10
          end
        end

        # 右側：請求書情報
        pdf.bounding_box([280, pdf.cursor + 100], width: 240) do
          pdf.text "請求書番号: #{@invoice.invoice_number}", size: 10
          pdf.move_down 5
          pdf.text "発行日: #{@invoice.issue_date.strftime('%Y年%m月%d日')}", size: 10
          pdf.move_down 5
          pdf.text "支払期限: #{@invoice.payment_due_date.strftime('%Y年%m月%d日')}", size: 10
          pdf.move_down 5
          pdf.text "請求期間: #{@invoice.billing_period_start.strftime('%Y年%m月%d日')} 〜 #{@invoice.billing_period_end.strftime('%Y年%m月%d日')}", size: 10
        end
      end

      pdf.move_down 30

      # 請求金額（大きく表示）
      pdf.bounding_box([0, pdf.cursor], width: 520) do
        pdf.stroke_bounds
        pdf.move_down 10
        pdf.text "ご請求金額", size: 12, align: :center
        pdf.move_down 5
        pdf.text "¥ #{number_with_delimiter(@invoice.total_amount)}", size: 20, align: :center
        pdf.move_down 5
        pdf.text "(消費税込み)", size: 10, align: :center
        pdf.move_down 10
      end

      pdf.move_down 20

      # 請求明細
      pdf.text "請求明細", size: 12
      pdf.move_down 10

      # 明細テーブル
      table_data = [
        ['日付', '内容', '数量', '単価', '金額']
      ]

      @invoice.invoice_items.each do |item|
        table_data << [
          item.order ? item.order.scheduled_date.strftime('%Y/%m/%d') : '',
          item.description,
          number_with_delimiter(item.quantity),
          "¥#{number_with_delimiter(item.unit_price)}",
          "¥#{number_with_delimiter(item.amount)}"
        ]
      end

      pdf.table(table_data, width: 520, cell_style: { size: 9, padding: [5, 5] }) do
        row(0).background_color = 'EEEEEE'
        column(2..4).align = :right
        cells.borders = [:top, :bottom, :left, :right]
      end

      pdf.move_down 20

      # 合計欄
      summary_data = [
        ['小計', "¥#{number_with_delimiter(@invoice.subtotal)}"],
        ['消費税(10%)', "¥#{number_with_delimiter(@invoice.tax_amount)}"],
        ['合計', "¥#{number_with_delimiter(@invoice.total_amount)}"]
      ]

      pdf.table(summary_data, position: :right, width: 260, cell_style: { size: 10, padding: [5, 10] }) do
        column(1).align = :right
        row(2).size = 12
        cells.borders = [:top, :bottom, :left, :right]
      end

      pdf.move_down 30

      # 振込先情報
      pdf.text "お振込先", size: 12
      pdf.move_down 10
      pdf.text "銀行名: みんなの社食銀行", size: 10
      pdf.text "支店名: 本店", size: 10
      pdf.text "口座種別: 普通預金", size: 10
      pdf.text "口座番号: 1234567", size: 10
      pdf.text "口座名義: カブシキガイシャミンナノシャショク", size: 10

      pdf.move_down 20

      # 備考
      if @invoice.notes.present?
        pdf.text "備考", size: 12
        pdf.move_down 5
        pdf.text @invoice.notes, size: 9
      end

      # フッター
      pdf.number_pages "ページ <page> / <total>",
                       at: [pdf.bounds.right - 100, 0],
                       size: 8,
                       align: :right
    end.render
  end

  private

  def number_with_delimiter(number)
    number.to_s.gsub(/(\d)(?=(\d{3})+(?!\d))/, '\\1,')
  end
end

module Admin
  class RecurringOrdersController < Admin::ApplicationController
    # 企業ごとにグループ化して表示（契約中・トライアル・見込みの企業をすべて表示）
    def index
      @companies = Company.includes(:recurring_orders)
                          .where(contract_status: ['active', 'trial', 'prospect'])
                          .order(:name)
    end

    # 企業単位で定期案件を編集
    def edit
      @company = Company.find(params[:id])
      # 登録済みの定期案件のみ取得
      @recurring_orders = @company.recurring_orders.order(:day_of_week)
    end

    def update
      @company = Company.find(params[:id])

      if @company.update(company_params)
        redirect_to admin_recurring_orders_path, notice: "#{@company.name}の定期案件を更新しました"
      else
        @recurring_orders = @company.recurring_orders.order(:day_of_week)
        render :edit, status: :unprocessable_entity
      end
    end

    # 一括注文生成アクション
    def bulk_generate
      from_date = params[:from_date].to_date
      to_date = params[:to_date].to_date

      result = RecurringOrderGenerator.generate_for_period(from_date, to_date)

      if result[:success]
        flash[:notice] = "#{result[:generated_count]}件の注文を生成しました（#{from_date.strftime('%Y/%m/%d')} 〜 #{to_date.strftime('%Y/%m/%d')}）"
      else
        flash[:error] = "#{result[:errors].size}件のエラーが発生しました。生成: #{result[:generated_count]}件"
      end

      redirect_to admin_recurring_orders_path
    end

    # 新規作成（company_idパラメータが必須）
    def new
      if params[:company_id].blank?
        redirect_to admin_recurring_orders_path, alert: '企業を選択してください'
        return
      end

      @company = Company.find(params[:company_id])
      # 登録済みの定期案件のみ取得（初回は空）
      @recurring_orders = @company.recurring_orders.order(:day_of_week)
    end

    def create
      @company = Company.find(params[:company_id])

      if @company.update(company_params)
        redirect_to admin_recurring_orders_path, notice: "#{@company.name}の定期案件を登録しました"
      else
        @recurring_orders = @company.recurring_orders.order(:day_of_week)
        render :new, status: :unprocessable_entity
      end
    end

    # 個別の定期案件から週次Order生成
    def generate_weekly
      @recurring_order = RecurringOrder.find(params[:id])
    end

    def create_weekly_orders
      @recurring_order = RecurringOrder.find(params[:id])

      # パラメータから開始日と終了日を取得
      from_date = params[:from_date].to_date
      to_date = params[:to_date].to_date

      begin
        # Orderを生成
        orders = @recurring_order.generate_orders_for_range(from_date, to_date)

        if orders.any?
          flash[:notice] = "#{orders.size}件のOrderを生成しました（#{from_date.strftime('%Y/%m/%d')} 〜 #{to_date.strftime('%Y/%m/%d')}）"
        else
          flash[:alert] = "指定期間内に生成可能なOrderはありませんでした（既に存在するか、配送曜日に該当する日がありません）"
        end

        redirect_to admin_recurring_order_path(@recurring_order)
      rescue => e
        flash[:error] = "Orderの生成に失敗しました: #{e.message}"
        redirect_to generate_weekly_admin_recurring_order_path(@recurring_order)
      end
    end

    private

    def company_params
      params.require(:company).permit(
        recurring_orders_attributes: [
          :id, :day_of_week, :meal_count, :delivery_time,
          :is_active, :status, :notes, :_destroy
        ]
      )
    end

    def resource_params
      params.require(:recurring_order).permit(
        dashboard.permitted_attributes(action_name) + [:company_id]
      )
    end

    # See https://administrate-demo.herokuapp.com/customizing_controller_actions
    # for more information
  end
end

module Admin
  class InvoicesController < Admin::ApplicationController
    # Administrate標準のRESTfulアクションのみを提供
    # カスタムアクションは以下の専用コントローラーに移動:
    # - InvoicePdfsController (PDF表示)
    # - InvoiceGenerationsController (一括生成)
  end
end

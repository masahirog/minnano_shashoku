# N+1クエリ検出設定
if defined?(Bullet)
  Bullet.enable = true
  Bullet.alert = false
  Bullet.bullet_logger = true
  Bullet.console = true
  Bullet.rails_logger = true
  Bullet.add_footer = true

  # 開発環境でのみ有効化
  Bullet.enable = Rails.env.development?
end

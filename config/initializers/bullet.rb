# N+1クエリ検出設定
if defined?(Bullet)
  Bullet.enable = true
  Bullet.alert = false
  Bullet.bullet_logger = true
  Bullet.console = true
  Bullet.rails_logger = true
  Bullet.add_footer = true

  # 開発環境とテスト環境で有効化
  Bullet.enable = Rails.env.development? || Rails.env.test?

  # テスト環境では例外を発生させる（N+1検出時にテスト失敗）
  if Rails.env.test?
    Bullet.raise = true
  end
end

# データベース設定の初期化
Rails.application.configure do
  # 環境変数からデータベース設定を明示的に設定
  if Rails.env.production?
    config.after_initialize do
      # 既存の接続を切断
      ActiveRecord::Base.connection_pool.disconnect!

      # 環境変数からデータベース設定を取得
      db_password = ENV['DB_PASSWORD']
      db_host = ENV['DB_HOST']
      db_username = ENV['DB_USERNAME']
      db_name = ENV['DB_NAME']
      db_port = ENV['DB_PORT'] || '5432'

      if db_password && db_host && db_username && db_name
        puts "Production database connection established"
        puts "Host: #{db_host}"
        puts "Database: #{db_name}"
        puts "Username: #{db_username}"
        puts "Port: #{db_port}"

        # 新しい接続を確立（個別の環境変数を使用）
        ActiveRecord::Base.establish_connection(
          adapter: 'postgresql',
          encoding: 'unicode',
          pool: ENV.fetch("RAILS_MAX_THREADS") { 5 },
          host: db_host,
          port: db_port,
          database: db_name,
          username: db_username,
          password: db_password,
          connect_timeout: 30,
          checkout_timeout: 10,
          reaping_frequency: 10,
          sslmode: 'require'
        )
      else
        puts "ERROR: Required database environment variables are missing!"
        puts "DB_HOST: #{db_host}"
        puts "DB_USERNAME: #{db_username}"
        puts "DB_NAME: #{db_name}"
        puts "DB_PASSWORD: #{db_password ? '[SET]' : '[NOT SET]'}"
        exit 1
      end
    end
  end
end

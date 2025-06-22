# This file should ensure the existence of records required to run the application in every environment (production,
# development, test). The code here should be idempotent so that it can be executed at any point in every environment.
# The data can then be loaded with the bin/rails db:seed command (or created alongside the database with db:setup).
#
# Example:
#
#   ["Action", "Comedy", "Drama", "Horror"].each do |genre_name|
#     MovieGenre.find_or_create_by!(name: genre_name)
#   end

# サンプルユーザーを作成
puts "サンプルユーザーを作成中..."
user = User.find_or_create_by(email: 'test@example.com') do |u|
  u.password = 'password123'
  u.password_confirmation = 'password123'
end

puts "ユーザー: (#{user.email}) (ID: #{user.id})"

# JWTトークンを生成
token = user.generate_jwt_token
puts "認証トークン: #{token}"

# 既存のTodoを削除（クリーンアップ）
user.todos.destroy_all

# サンプルTodoを作成
puts "サンプルTodoを作成中..."
todos = [
  {
    title: '買い物に行く',
    description: 'スーパーで食材を買う',
    completed: false
  },
  {
    title: 'Reactの勉強',
    description: 'React Hooksについて学習する',
    completed: true
  },
  {
    title: 'プロジェクトの設計',
    description: '新しいプロジェクトのアーキテクチャを考える',
    completed: false
  }
]

todos.each do |todo_attrs|
  todo = user.todos.create!(todo_attrs)
  puts "Todo作成: #{todo.title} (#{todo.completed ? '完了' : '未完了'})"
end

puts "Seeds完了！"
puts "ログイン情報:"
puts "Email: test@example.com"
puts "Password: password123"
puts "認証トークン: #{token}"
puts ""
puts "フロントエンドで使用する場合:"
puts "Authorization: Bearer #{token}"

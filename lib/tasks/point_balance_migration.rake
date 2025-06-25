namespace :data_migration do
  desc "Convert product point_balance from dollars to cents"
  task update_user_point_balance_to_cents: :environment do
    User.find_each do |u|
      next unless u.point_balance
      new_point_balance = u.point_balance * 100
      u.update_columns(point_balance: new_point_balance.round)
    end
    puts "User point_balance migration complete."
  end
end

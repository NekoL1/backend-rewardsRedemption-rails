namespace :data_migrate do
  desc "Set discount as integer pervent based on user's VIP grade"
  task set_discount_from_vip_grade: :environment do
    Redemption.find_each do |redemption|
      vip_grade = redemption.vip_grade || 0
      discount_percent = [ vip_grade * 10, 50 ].min
      redemption.update_columns(discount: discount_percent)
    end
  end
end

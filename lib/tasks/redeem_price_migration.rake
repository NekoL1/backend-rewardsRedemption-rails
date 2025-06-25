namespace :data_migration do
  desc "Convert redemption redeem_price and redeem_points from dollars to cents"
  task update_redemption_points_to_cents: :environment do
    Redemption.find_each do |r|
      next unless r.redeem_points &&  r.redeem_price
      new_redeem_price = r.redeem_price * 100
      new_redeem_points = r.redeem_points * 100
      r.update_columns(redeem_price: new_redeem_price.round, redeem_points: new_redeem_points.round)
    end
    puts "Redemption migration complete."
  end
end

namespace :data_migration do
  desc "Convert product redeem_price from dollars to cents"
  task update_product_price_to_cents: :environment do
    Product.find_each do |p|
      next unless p.redeem_price
      new_redeem_price = p.redeem_price * 100
      p.update_columns(redeem_price: new_redeem_price.round)
    end
    puts "Product redeem_price migration complete."
  end
end

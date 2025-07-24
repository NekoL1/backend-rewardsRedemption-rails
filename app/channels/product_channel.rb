class ProductChannel < ApplicationCable::Channel
  def subscribed
    # stream_from "some_channel"
    def subscribed
      stream_from "product_#{params[:product_id]}"
      Rails.logger.info("✅ Subscribing to stream: #{stream_name}")
      stream_from stream_name
    end
  end

  def unsubscribed
     # Any cleanup needed when channel is unsubscribed
     Rails.logger.info("❌ Unsubscribed from product_#{params[:product_id]}")
  end
end

class UserChannel < ApplicationCable::Channel
  def subscribed
    # stream_from "some_channel"
    stream_from "user_#{params[:user_id]}" # This makes the connection specific to each user.
  end

  def unsubscribed
    # Any cleanup needed when channel is unsubscribed
  end
end

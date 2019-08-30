class PlanChannel < ApplicationCable::Channel
  def subscribed
    stream_from "plan_channel_#{params[:plan_id]}" #"plan_channel_#{plan.id}"
  end

  def unsubscribed
    # Any cleanup needed when channel is unsubscribed
  end

  def speak(data)
  	# PlanMessage.create!(content: data['message'], plan_id: 37, user_id: 40)
  	# ActionCable.server.broadcast 'plan_channel', message: data['message']
  end

end

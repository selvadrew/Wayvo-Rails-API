class PlanMessageBroadcastJob < ApplicationJob
  queue_as :default

  def perform(message)
  	require 'fcm'
		fcm = FCM.new("AAAAAOXsHmg:APA91bFeO5xEEP3Zqkg1Ht3ocwzphQ9uEFGdUHHbRsGHAaVSqEXdJWAUo026ENDbFKJ6Sxy7UFRBYmm-ZH6NOkBGRbZvWhWtm8beW0lRtJivIdoExzfkiYk5QWj98kfTB9-sE4gD6oX-")
  	activities = ["grab food", "hang out", "group study", "party"]

  	senders_name = message.user.fullname
  	if message.plan.group_type == "Program"
  		group_name = message.plan.group.program_name
  	else
  		group_name = message.plan.group.name
  	end

  	##notification stuff
    firebase_tokens = User.joins(:plan_members)
    	.where(plan_members: {user_id: message.plan.plan_members.pluck(:user_id)})
    	.where.not(plan_members: {user_id: message.user_id})
    	.pluck(:firebase_token)
    	.uniq

    if message.system_message 
    	incoming_message = {
	  		plan_id: message.plan_id,
	  		message_data: {
					_id: message.id,
	        text: message.content,
	        createdAt: message.created_at,
	        system: true#,
	        # user: {
	        #   _id: message.user_id,
	        #   name: senders_name
	        # }
	  		}
	  	}
	  	#notification data 
	  	firebase_tokens.push(message.user.firebase_token) #send current_user status notifs too 
	    registration_ids = firebase_tokens
	    @notification = {
	        title: "#{group_name}",
	        body: "#{message.content}",
	        sound: "default"
	      }

	    options = {notification: @notification, priority: 'high', data: {outgoing: true}}
	    response = fcm.send(registration_ids, options)

    else
    	#not system message
	  	#action cable stuff 
	  	incoming_message = {
	  		plan_id: message.plan_id,
	  		message_data: {
					_id: message.id,
	        text: message.content,
	        createdAt: message.created_at,
	        user: {
	          _id: message.user_id,
	          name: senders_name
	        }
	  		}
	  	}
			#notification data 
	    registration_ids = firebase_tokens
	    @notification = {
	        title: "#{senders_name} in #{group_name}",
	        body: "#{message.content}",
	        sound: "default"
	      }

	    options = {notification: @notification, priority: 'high', data: {outgoing: true}}
	    response = fcm.send(registration_ids, options)
	  end

	  ActionCable.server.broadcast "plan_channel_#{message.plan_id}", incoming_message: incoming_message

  end

end

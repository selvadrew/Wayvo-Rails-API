class Api::V1::AcceptorsController < ApplicationController
	before_action :authenticate_with_token!

	def create
		require 'fcm'
		fcm = FCM.new("AAAAAOXsHmg:APA91bFeO5xEEP3Zqkg1Ht3ocwzphQ9uEFGdUHHbRsGHAaVSqEXdJWAUo026ENDbFKJ6Sxy7UFRBYmm-ZH6NOkBGRbZvWhWtm8beW0lRtJivIdoExzfkiYk5QWj98kfTB9-sE4gD6oX-")
		firebase_token = []
		
		@notification = {
			title: "Expect a call shortly",
			body: "#{current_user.fullname} just said hello back!",
			sound: "default"
		}
		
		options = {notification: @notification, priority: 'high', data: {expect_call: true}}

		@outgoing = Outgoing.find_by(id: params[:outgoing_id])
		time_gap = 5.minutes

		if Acceptor.find_by(outgoing_id: params[:outgoing_id])
			render json: { error: "This call has already been connected or has expired", is_success: false}, status: 404
		elsif @outgoing.created_at < DateTime.now.utc - @outgoing.seconds == true 
			render json: { error: "This call has already been connected or has expired", is_success: false}, status: 404
		else
			@acceptor = Acceptor.new(:outgoing_id => params[:outgoing_id])
			@acceptor.user_id = current_user.id
			@outgoing = Outgoing.where(id: @acceptor.outgoing_id).first

			#figure out who to send "got matched" notification to 
			@got_matched = User.find_by(id: @outgoing.user_id)
			fire_token = @got_matched.firebase_token
			firebase_token << fire_token
			registration_ids = firebase_token

			if @outgoing.user_id == current_user.id
				render json: { error: "Can't accept your own outgoing call", is_success: false}, status: 404

		    elsif @acceptor.save
		      render json: {is_success: true}, status: :ok
		      response = fcm.send(registration_ids, options)

		    else
		      render json: { error: "This call has already been connected or has expired", is_success: false}, status: 404
		    end
				
		end
	end

end
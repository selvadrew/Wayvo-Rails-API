class Api::V1::OutgoingsController < ApplicationController
	before_action :authenticate_with_token!
	# before_action :anyone_active, only: [:create]
	

	def create
		require 'fcm'
		fcm = FCM.new("AAAAAOXsHmg:APA91bFeO5xEEP3Zqkg1Ht3ocwzphQ9uEFGdUHHbRsGHAaVSqEXdJWAUo026ENDbFKJ6Sxy7UFRBYmm-ZH6NOkBGRbZvWhWtm8beW0lRtJivIdoExzfkiYk5QWj98kfTB9-sE4gD6oX-")

		#queries 
		say_hello_to_friends = User.contacts_get_notified(current_user)
		friends_added = Friendship.where(user_id: current_user).first 
		last_hello = Outgoing.where(user_id: current_user.id).last

		friends = say_hello_to_friends.map{|x| x[:fullname]}


		#check if anyone is active 
		filter_date = DateTime.now.utc - 65.minutes
		latest_outgoings = Outgoing.where("created_at > ?", filter_date).where(user_id: Friendship.all.where(friend_id: current_user, status: "FRIENDSHIP", receive_notifications: true, send_notifications: true ).pluck(:user_id)).order(:created_at)

		active_output = []
		latest_outgoings.each do |outgoing|

			@got_accepted = Acceptor.find_by(outgoing_id: outgoing.id)
			if @got_accepted 
				#connected with someone  
				allowed = true
			else 
				if (DateTime.now.utc - outgoing.seconds) > outgoing.created_at == true
					# Created at ... Now - 10min 
					#if not connected and outgoing created_at is greater than now minus outgoing seconds 
					allowed = true
				else 
					allowed = false 
				end
			end

			call_details = {allowed: allowed}
			unless allowed
				active_output << call_details
			end
		end

	    if active_output.count === 0
	    	@allowed = true
	    else
	      	@allowed = false 
	    end



		#notification content
		registration_ids = say_hello_to_friends.map{|x| x[:firebase_token]}
    @notification = {
			title: "Hello, it's #{current_user.fullname}",
			#body: "Say Hello Back to start a call with me",
			body: "Let's catch up if you're free right now. Say Hello Back to start a call with me.",
			sound: "default"
		}
		options = {notification: @notification, priority: 'high', data: {outgoing: true}}

		@outgoing = current_user.outgoings.build
		@outgoing.seconds = params[:seconds]

		# you can only say hello every... 
		time_gap = 15.minutes
		time_gap_string = "15 minutes"

		active_gap = 5.minutes

		if last_hello == nil
			can_call = true
		elsif last_hello.created_at < DateTime.now.utc - time_gap == true 
			can_call = true 
		else 
			can_call = false 

			# calculate how long they have to wait 
			last_time = last_hello.created_at
			last_time_formatted = last_time.to_time
			wait_time = (time_gap.to_i - (last_time_formatted - DateTime.now.utc).to_i.abs) / 60
		end

		if @allowed 
			unless friends_added
				render json: { error: "You don't have contacts to Say Hello to. Start adding contacts by username.", contact_is_live: false, is_success: false}, status: :ok
			else
			  case can_call
					when true
				    if @outgoing.save && response = fcm.send(registration_ids, options)
				      render json: {last_said_hello: @outgoing.created_at, countdown_timer: @outgoing.seconds, is_success: true, test: say_hello_to_friends }, status: :ok
				    else
				      render json: { error: "Can't Say Hello right now", contact_is_live: false, is_success: false}, status: 404
				    end
					else			
					  render json: { error: "Sorry, you can only Say Hello every #{time_gap_string}. Try again in #{wait_time} minutes.", time: wait_time, contact_is_live: false, is_success: false}, status: :ok
				end
			end
		else 
			render json: { error: "You can't Say Hello when a contact is live, Say Hello Back to them instead.", contact_is_live: true, is_success: false}, status: :ok
		end
	end


	def check_active 

		time_gap = 5.minutes
		keep_showing_active = 15.minute

		# finds Outgoings where the date created is greater than now-65min and where the user is friends with me
		filter_date = DateTime.now.utc - 65.minutes
		latest_outgoings = Outgoing.where("created_at > ?", filter_date).where(user_id: Friendship.all.where(friend_id: current_user, status: "FRIENDSHIP", receive_notifications: true, send_notifications: true ).pluck(:user_id)).order(:created_at)


		active_output = []
		latest_outgoings.each do |outgoing|
			@user = User.find_by(id: outgoing.user_id)

			@got_accepted = Acceptor.find_by(outgoing_id: outgoing.id)
			if @got_accepted && @got_accepted.created_at > DateTime.now.utc - keep_showing_active == true
				#if connected with anyone, just keep showing for 15 minutes. 
				active = true
			else 
				if (DateTime.now.utc - outgoing.seconds - 5.minutes) < outgoing.created_at == true
					#if not connected and outgoing created_at is greater than now minus outgoing seconds 
					active = true 
				else 
					active = false
				end
			end


			#check if current user is connected 
			connection = Acceptor.where(outgoing_id: outgoing.id).where(user_id: current_user.id).first
			if connection && connection.created_at > DateTime.now.utc - keep_showing_active == true 
				connected = true
			else
				connected = false
			end

			call_details = {outgoing_id: outgoing.id , fullname: @user.fullname, phone_number: @user.phone_number, ios: @user.iOS, active: active, connected: connected}
			if call_details[:active] || call_details[:connected]
				active_output << call_details
			end
		end

    if latest_outgoings
      render json: {latest_outgoings: active_output, is_success: true }, status: :ok
    else
      render json: { error: "error", is_success: false}, status: 404
    end		
	end



	def last_connected

		@last_outgoing = Outgoing.where(user_id: current_user.id).last
		@last_accepted = Acceptor.where(user_id: current_user.id).last

		# if ever pressed Say Hello
		if @last_outgoing
			last_said_hello = @last_outgoing.created_at
			countdown_timer = @last_outgoing.seconds
			ac = Acceptor.find_by(outgoing_id: @last_outgoing.id)
			if ac 
				connected_with_outgoing = User.find_by(id: ac.user_id)
				ac_date = ac.created_at
			end
		end

		# if ever accepted a Say Hello from Active tab
		if @last_accepted
			og = Outgoing.find_by(id: @last_accepted.outgoing_id)
			connected_with_accepted = User.find_by(id: og.user_id)
			og_date = @last_accepted.created_at
		end

		if connected_with_outgoing || connected_with_accepted
			fc = connected_with_outgoing || connected_with_accepted
			final_connection = fc.fullname
		else
			final_connection = false
		end

		# if pressed Say Hello and got accepted AND accepted Say Hello from Active tab
		if ac && @last_accepted
			if ac_date > og_date
				connected_with = connected_with_outgoing.fullname
				render json: {connected_with: connected_with, can_say_hello: true, is_success: true }, status: :ok
			else
				connected_with = connected_with_accepted.fullname
				render json: {connected_with: connected_with, can_say_hello: true, is_success: true }, status: :ok
			end

		# if only one of the above is true 
		elsif @last_outgoing || connected_with_accepted
			if connected_with_outgoing 
				render json: {connected_with: final_connection, can_say_hello: true, is_success: true }, status: :ok
			else
				if @last_outgoing
					if (countdown_timer - (DateTime.now.utc - @last_outgoing.created_at)) > 0 
						render json: {connected_with: final_connection, can_say_hello: false, last_said_hello: last_said_hello, countdown_timer: countdown_timer, is_success: true }, status: :ok
					else
						render json: {connected_with: final_connection, can_say_hello: true, is_success: true }, status: :ok
					end
				else
					render json: {connected_with: final_connection, can_say_hello: true, is_success: true }, status: :ok
				end
			end

		# if pressed Say Hello and not connected AND never accepted from Active Tab 
		else
			render json: {error: "error", is_success: false}, status: 404
		end
	end


	def tester
		a = User.contacts_get_notified(current_user)
		b = User.friendship_status(current_user)

		render json: {data: a, other: b}
	end



	# private 
		# def anyone_active
		# # finds Outgoings where the date created is greater than now-65min and where the user is friends with me
		# filter_date = DateTime.now.utc - 65.minutes
		# latest_outgoings = Outgoing.where("created_at > ?", filter_date).where(user_id: Friendship.all.where(friend_id: current_user, status: "FRIENDSHIP", receive_notifications: true, send_notifications: true ).pluck(:user_id)).order(:created_at)


		# active_output = []
		# latest_outgoings.each do |outgoing|
		# 	@user = User.find_by(id: outgoing.user_id)

		# 	@got_accepted = Acceptor.find_by(outgoing_id: outgoing.id)
		# 	if @got_accepted 
		# 		#connected with someone  
		# 		allowed = true
		# 	else 
		# 		if (DateTime.now.utc - outgoing.seconds) > outgoing.created_at == true
		# 			# Created at ... Now - 10min 
		# 			#if not connected and outgoing created_at is greater than now minus outgoing seconds 
		# 			allowed = true
		# 		else 
		# 			allowed = false 
		# 		end
		# 	end

		# 	call_details = {fullname: @user.fullname, allowed: allowed}
		# 	if call_details[:allowed] 
		# 		active_output << call_details
		# 	end
		# end

	 #    if active_output.count === 0
	 #    	@allowed = true
	 #    else
	 #      	@allowed = false 
	 #    end
		# end


end














class Api::V1::CalendarsController < ApplicationController
	  before_action :authenticate_with_token!, only: [:get_calendar, :set_calendar, :show_friends_calendar, :book_friends_calendar]

	  # check if todays date is the same - with actual date, front end date, and saved date in database 
	  # when getting calendar, update the entire calendar -> when setting the calendar, if the dates dont match, show 
	  #    calendar is updated alert, and get calendar without setting it(since the date they picked would be wrong on the front end)

	def get_calendar 
		@calendar = @current_user.calendar 
		todays_date_for_user = (Time.current.utc + @current_user.time_zone_offset.minutes).to_date

		if @calendar
			todays_schedule = {}
			tomorrows_schedule = {}

			@calendar.schedule.each do |time, status|
				# get time and convert all times used to users time zone before doing anything 
				users_time = DateTime.parse(time) + @current_user.time_zone_offset.minutes
				
				# users actual date in their time zone and formatted time in schedule to users time zone 
				date = users_time.to_date 
				formatted_time = users_time.strftime("%-I:%M%p").downcase
				
				if date == todays_date_for_user
					todays_schedule[formatted_time] = status 
				elsif date == (todays_date_for_user + 1.day)
					tomorrows_schedule[formatted_time] = status 
				else 
					# if outdated, remove from schedule and place in archive 
					@calendar.schedule.except!(time)
					@calendar.archive[time] = status 
				end
			end
			
			render json: {is_success: true, todays_schedule: todays_schedule, tomorrows_schedule: tomorrows_schedule}
			
			@calendar.save 	
			@calendar.touch 

		else
			Calendar.new(
				user: @current_user, 
				schedule: {},
				archive: {}
		)
		@current_user.calendar.save 
		render json: {is_success: true, todays_schedule: {}, tomorrows_schedule: {} }, status: :ok 
		end

	end 


	def set_calendar 
		# check that last updated == date today - if not, need to get calendar again 
		# add time if free status, remove time if busy status 
		# note: everything should be handled in utc since its saving to db

		@calendar = @current_user.calendar 
		time = params[:time]
		status = params[:status]
		# params day, 1 = today, 2 = tomorrow 
		next_day = params[:day].to_i - 1 

		#find updated_at and current date in users time zone - updated_at is when the user last got/loaded the calendar 
		updated_at = (@calendar.updated_at + @current_user.time_zone_offset.minutes).to_date 
		current_user_date = (Time.current.utc + @current_user.time_zone_offset.minutes).to_date

		utc_selected_time = DateTime.parse(time).utc - @current_user.time_zone_offset.minutes + next_day.day 
		current_status_for_selection = @calendar.schedule[utc_selected_time.to_s]

		# check if the user has the right calendar view and if the time was already booked via invitation from another user 
		if updated_at == current_user_date && current_status_for_selection != "call"

			if status == "free"
				@calendar.schedule[utc_selected_time] = "free"
			elsif status == "busy" 
				@calendar.schedule.except!(utc_selected_time.to_s)
			end

			if @calendar.save
				render json: { is_success: true }, status: :ok
			else 
				render json: { is_success: false, get_calendar: true }, status: :ok 
			end

		else # need to get calendar before updating because their screen expired 
			render json: { is_success: false, get_calendar: true }, status: :ok 
		end

	end


	def show_friends_calendar 
		#arr is to sort daily times to show 
		arr = ["8:00am", "8:30am", "9:00am", "9:30am","10:00am","10:30am","11:00am","11:30am","12:00pm","12:30pm","1:00pm","1:30pm","2:00pm","2:30pm","3:00pm","3:30pm","4:00pm","4:30pm","5:00pm","5:30pm","6:00pm","6:30pm","7:00pm","7:30pm","8:00pm","8:30pm","9:00pm","9:30pm","10:00pm","10:30pm","11:00pm","11:30pm"]
		@invitation = Invitation.find_by_id(params[:invitation_id]) 
  		@inviter = User.find_by_id(@invitation.user_id)
  		@inviter_calendar = @inviter.calendar 
  		@invitee_calendar = @current_user.calendar 

  		todays_date_for_user = (Time.current.utc + @current_user.time_zone_offset.minutes).to_date

  		todays_schedule = []
		tomorrows_schedule = []

  		@inviter_calendar.schedule.each do |time, status|
  			#users time is what the "free" time is for the users time zone 
  			users_time = DateTime.parse(time) + @current_user.time_zone_offset.minutes
  			date = users_time.to_date 

  			if date == todays_date_for_user && status == "free"
  				todays_schedule.push(users_time.strftime("%-I:%M%p").downcase)
  			elsif date == (todays_date_for_user + 1.day) && status == "free"
  				tomorrows_schedule.push(users_time.strftime("%-I:%M%p").downcase)
  			end
  		end

  		todays_schedule_ordered = todays_schedule.sort_by &arr.method(:index)
  		tomorrows_schedule_ordered = tomorrows_schedule.sort_by &arr.method(:index)

  		@invitation.touch(:last_viewed)

  		render json:{ is_success: true, todays_dates: todays_schedule_ordered, tomorrows_dates: tomorrows_schedule_ordered, updated_at: @inviter_calendar.updated_at }, status: :ok
		
	end

	
	def book_friends_calendar 
		require 'fcm'
    	fcm = FCM.new("AAAAAOXsHmg:APA91bFeO5xEEP3Zqkg1Ht3ocwzphQ9uEFGdUHHbRsGHAaVSqEXdJWAUo026ENDbFKJ6Sxy7UFRBYmm-ZH6NOkBGRbZvWhWtm8beW0lRtJivIdoExzfkiYk5QWj98kfTB9-sE4gD6oX-")
    	registration_ids = []
		# params day will be today or tomorrow 
	  	# params time selected 
	  	# params updated_at 
	  	# params invitation_id 
	  	# params day, 1 = today, 2 = tomorrow 
	  	next_day = params[:day].to_i - 1 
	  	@invitation = Invitation.find_by_id(params[:invitation_id])
	  	time = params[:time]
	  	viewer_calendar_last_updated = DateTime.parse(params[:updated_at]).to_i

	  	scheduled_date = DateTime.parse(time).utc - @current_user.time_zone_offset.minutes + next_day.day
	  	utc_selected_time = scheduled_date.to_s

	  	@inviter = User.find_by_id(@invitation.user_id)
	  	@inviter_calendar = @inviter.calendar 
	  	@invitee_calendar = @current_user.calendar 
	  	

	  	# if updated_at dates arent the same, the inviter updated the calender since the last time it was loaded by invitee
	  	if viewer_calendar_last_updated == @inviter_calendar.updated_at.to_i

	  		# can we schedule call the call?
			inviter_free = false 
			invitee_free = false 

			# check that it is free for inviter
			inviter_status = @inviter_calendar.schedule[utc_selected_time]
			if inviter_status == "free"
				@inviter_calendar.schedule[utc_selected_time] = "call"
				inviter_free = true
			end

			# check that its free or null for current user 
			invitee_status = @invitee_calendar.schedule[utc_selected_time]
			if invitee_status == "free" || invitee_status == nil 
				@invitee_calendar.schedule[utc_selected_time] = "call"
				invitee_free = true  
			end

			#invitation scheduled call 
			@invitation.scheduled_call = scheduled_date

			send_notification = false 
			if inviter_free && invitee_free
				if @inviter_calendar.save! && @invitee_calendar.save! && @invitation.save!  
					render json:{ is_success: true }
					send_notification = true  
				else
					render json:{ is_success: false, reload: true, error: "saving error" }
				end
			else
				render json:{ is_success: false, reload: true, error: "not free anymore"}
			end


			if send_notification
				#figure out time in notification
				notification_text = scheduled_date + @inviter.time_zone_offset.minutes
    			formatted_time = notification_text.strftime("%-I:%M%p").downcase

    			#figure out day in notificaiton 
    			notification_day = ""
    			todays_date_for_user = (Time.current.utc + @inviter.time_zone_offset.minutes).to_date
    			tomorrows_date_for_user = todays_date_for_user + 1 
    			if notification_text.to_date == todays_date_for_user
    				notification_day = "today"
    			elsif notification_text.to_date == tomorrows_date_for_user
    				notification_day = "tomorrow"
    			end


				@notification = {
          				title: "🎉 #{@current_user.first_name} just joined your Calendar 🎉",
          				body: "Call #{@current_user.first_name} #{notification_day} at #{formatted_time}. Wayvo will send you a reminder shortly before your call.", #Call #{@inviter.first_name} at 10:00am tomorrow (party emoticon). 
          				sound: "default"
        		} 

				registration_ids << @inviter.firebase_token

    			options = { notification: @notification, priority: 'high', data: { upcoming: true } }
    			response = fcm.send(registration_ids, options)

			end

			# need to use transaction for the above - https://api.rubyonrails.org/classes/ActiveRecord/Transactions/ClassMethods.html
			# Calendar.transaction do 
			# 	Invitation.transaction do 
			# 		# save both calendars, then update invitation object, send notification 
			# 		if inviter_free && invitee_free
			# 			begin
			# 				if @inviter_calendar.save! && @invitee_calendar.save! && @invitation.save!  
			# 					render json:{ is_success: true }
			# 				end
			# 			rescue
			# 				render json:{ is_success: false, reload: true }
			# 				raise ActiveRecord::Rollback
			# 			end

			# 		else
			# 			render json:{ is_success: false, reload: true }
			# 		end
			# 	end
			# end

	  	else
	  		render json:{ is_success: false, reload: true, error: "calendar updated" }, status: :ok
	  	end

	end

	
end



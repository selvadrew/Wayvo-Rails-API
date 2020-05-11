class Api::V1::CalendarsController < ApplicationController
	  before_action :authenticate_with_token!, only: [:get_calendar, :set_calendar, :update_calendar, :show_friends_calendar, :book_friends_calendar]

	  # check if todays date is the same - with actual date, front end date, and saved date in database 
	  # when getting calendar, update the entire calendar -> when setting the calendar, if the dates dont match, show 
	  #    calendar is updated alert, and get calendar without setting it(since the date they picked would be wrong on the front end)

	  def get_calendar
	  	#first update or create calendar 
	  	# save todays date
	  	date_today_in_utc = Time.current.utc
	  	date_tomorrow_in_utc = date_today_in_utc + 24.hours 
	  	@calendar = @current_user.calendar  

	  	if @calendar 
	  		users_date_today = (date_today_in_utc + @current_user.time_zone_offset.minutes).to_date 
	  		users_saved_date_today = (Time.parse(@calendar.schedule["todays_date"]) + @current_user.time_zone_offset.minutes).to_date 
	  		users_saved_date_tomorrow = (Time.parse(@calendar.schedule["tomorrows_date"]) + @current_user.time_zone_offset.minutes).to_date 
	  		
	  		# actual today == saved today 
	  		if users_date_today == users_saved_date_today
	  			# do nothing since calendar is up to date 

	  		# actual today == saved tomorrow -> therefore need to update today with tomorrows saved data and make tomorrow blank
	  		elsif users_date_today == users_saved_date_tomorrow
	  			@calendar.schedule = {
	  				todays_date: date_today_in_utc,
	  				tomorrows_date: date_tomorrow_in_utc, 
	  				todays_schedule: @calendar.schedule["tomorrows_schedule"],
	  				tomorrows_schedule: {}
	  			}

	  		# both dates are not relevant anymore 
	  		else
	  			@calendar.schedule = {
	  				todays_date: date_today_in_utc,
	  				tomorrows_date: date_tomorrow_in_utc, 
	  				todays_schedule: {},
	  				tomorrows_schedule: {}
	  			}
	  		end

	  	else # user doesnt have a calendar, so create it for them 
	  		Calendar.new(
	  			user: @current_user, 
	  			schedule: {
					todays_date: date_today_in_utc,
					tomorrows_date: date_tomorrow_in_utc,
					todays_schedule: {},
					tomorrows_schedule: {}
				}
			)
	  	end

	  	# if the calendar is saved successfully, change utc times to users time and send the data 
	  	if @current_user.calendar.save 

  			todays_schedule_normalized = {}
			@current_user.calendar.schedule["todays_schedule"].each do |time, status|
				standard_time = (Time.parse(time) + @current_user.time_zone_offset.minutes).strftime("%-I:%M%p").downcase
				todays_schedule_normalized[standard_time] = status 
			end

			tomorrows_schedule_normalized = {}
			@current_user.calendar.schedule["tomorrows_schedule"].each do |time, status|
				standard_time = (Time.parse(time) + @current_user.time_zone_offset.minutes).strftime("%-I:%M%p").downcase
				tomorrows_schedule_normalized[standard_time] = status 
			end

	  		render json: {is_success: true, todays_schedule: todays_schedule_normalized, tomorrows_schedule: tomorrows_schedule_normalized }, status: :ok
	  	else
	  		render json: {is_success: false}, status: :ok 
	  	end
	  	
	  end

	  def set_calendar
	  	# get todays date
	  	date_today_in_utc = Time.current.utc
	  	users_date_today = (date_today_in_utc + @current_user.time_zone_offset.minutes).to_date 
	  	
	  	@calendar = @current_user.calendar 
	  	users_saved_date_today = (Time.parse(@calendar.schedule["todays_date"]) + @current_user.time_zone_offset.minutes).to_date 
	  	
	  	# actual today == saved today - if false, you need to get_calendar (refresh the users front end)
	  	if users_date_today == users_saved_date_today
	  		day = params[:day]
	  		utc_time = (Time.parse(params[:time]) - @current_user.time_zone_offset.minutes).strftime("%-I:%M%p").downcase
	  		status = params[:status]
	  		if day == 1 
	  			schedule_to_update = @calendar.schedule["todays_schedule"]
	  			schedule_day = "todays_schedule"
	  		else
	  			schedule_to_update = @calendar.schedule["tomorrows_schedule"]
	  			schedule_day = "tomorrows_schedule"
	  		end

	  		# if user is setting the status to free, add the element. If user is setting to busy, get rid of the element
	  		if status == "free"
	  			schedule_to_update[utc_time] = "free"
	  			new_schedule = schedule_to_update
	  		elsif status == "busy" 
	  			new_schedule = schedule_to_update.except(utc_time)
	  		end

	  		@calendar.schedule[schedule_day] = new_schedule

	  		if @current_user.calendar.save
	  			render json: {is_success: true}, status: :ok 
	  		else
	  			render json: {is_success: false, get_calendar: true}, status: :ok 
	  		end

	  	else # need to get calendar before updating 
	  		render json: {is_success: false, get_calendar: true}, status: :ok 
	  	end

	  end



  def show_friends_calendar 
  	# receive id 
  	# get today and tomorrow- if not show false 
  	# if i want to see my friends calendar - i need to get their calendar and change it to my time zone 
  	# after selecting a time, it would need to change back to utc prob
  	invitation = Invitation.find_by(id: params[:invitation_id], user_id: params[:user_id])
  	@inviter = User.find_by(id: params[:user_id])
  	date_today_in_utc = Time.current.utc
  	updated_at = @inviter.calendar.updated_at
  
  	if invitation 
  		users_date_today = (date_today_in_utc + @current_user.time_zone_offset.minutes).to_date 
	  	inviters_saved_date_today = (Time.parse(@inviter.calendar.schedule["todays_date"]) + @current_user.time_zone_offset.minutes).to_date 
	  	inviters_saved_date_tomorrow = (Time.parse(@inviter.calendar.schedule["tomorrows_date"]) + @current_user.time_zone_offset.minutes).to_date 

  		# actual today == saved today 
  		if users_date_today == inviters_saved_date_today
  			# get today/tomorrow dates and show in the current users time zone
	  		todays_schedule_normalized = show_friends_selected_times(@inviter, "todays_schedule")
			tomorrows_schedule_normalized = show_friends_selected_times(@inviter, "tomorrows_schedule")

  		# actual today == saved tomorrow -> therefore today options should be blank 
  		elsif users_date_today == inviters_saved_date_tomorrow
  			# get tomorrows saved database dates and show as todays dates for the user 	
  			todays_schedule_normalized = show_friends_selected_times(@inviter, "tomorrows_schedule")
			tomorrows_schedule_normalized = []

  		# both dates are not relevant anymore 
  		else
  			todays_schedule_normalized = []
  			tomorrows_schedule_normalized = []
  		end

	  	render json:{ is_success: true, todays_dates: todays_schedule_normalized, tomorrows_dates: tomorrows_schedule_normalized, updated_at: updated_at }, status: :ok

	else 
		render json:{ is_success: false }, status: :ok
  	end

  end 


  def book_friends_calendar 

  	# params day will be today or tomorrow 
  	# params time selected 
  	# params updated_at 
  	# params invitation_id 

  	@invitation = Invitation.find_by_id(params[:invitation_id])
  	@inviter = User.find_by_id(@invitation.user_id)
  	if params[:day] == 1 
  		day = "todays_schedule"
  		scheduled_day = 0
  	else 
  		day = "tomorrows_schedule"
  		scheduled_day = 1 
  	end

  	# if true, friend updated their calendar 
	if false#@inviter.calendar.updated_at > Time.parse(params[:updated_at])
		render json:{ is_success: false, reload: true,  db: @inviter.calendar.updated_at, param: Time.parse(params[:updated_at])}, status: :ok
	else
		# schedule call
		inviter_free = false 
		current_user_free = false 

		# figure out utc time 
		utc_time_selected = (Time.parse(params[:time]) - @current_user.time_zone_offset.minutes).strftime("%-I:%M%p").downcase

		# check that it is free for inviter
		inviter_status = @inviter.calendar.schedule[day][utc_time_selected]
		if inviter_status == "free"
			@inviter.calendar.schedule[day][utc_time_selected] = "Call"
			inviter_free = true
		end

		# check that its free or null for current user 
		current_user_status = @current_user.calendar.schedule[day][utc_time_selected]
		if current_user_status == "free" || current_user_status == nil 
			@current_user.calendar.schedule[day][utc_time_selected] = "Call"
			current_user_free = true
		end


		

		# format invitation.scheduled_call field 
		# what time(t) did the user pick 
		t = Time.parse(params[:time])
		# what day/time is it for the user now 
		d = Time.current.utc + @current_user.time_zone_offset.minutes
		year = d.year 
		month = d.month 
		day = d.day + scheduled_day
		hour = t.hour 
		min = t.min 

		scheduled_datetime = DateTime.new(year, month, day, hour, min, 0).utc - @current_user.time_zone_offset.minutes
		@invitation.scheduled_call = scheduled_datetime

		Calendar.transaction do 
			Invitation.transaction do 
				# save both calendars, then update invitation object, send notification 
				if @inviter.calendar.save! && @current_user.calendar.save! && @invitation.save! && inviter_free && current_user_free
					render json:{ is_success: true }

				else
					render json:{ is_success: false, reload: true, inviter_free: inviter_free, current_user_free:current_user_free }
					raise ActiveRecord::Rollback
				end
			end
		end
		

		# render json:{ is_success: true, time: utc_time_selected, inviter_status: inviter_status, current_user_status:current_user_status }, status: :ok
	end


  	# use today/tomorrow and time selected to create scheduled_at field 
  	# update both users calendars  


  end




private 

  def show_friends_selected_times(inviter, schedule_day)
  	arr = ["8:00am", "8:30am", "9:00am", "9:30am","10:00am","10:30am","11:00am","11:30am","12:00pm","12:30pm","1:00pm","1:30pm","2:00pm","2:30pm","3:00pm","3:30pm","4:00pm","4:30pm","5:00pm","5:30pm","6:00pm","6:30pm","7:00pm","7:30pm","8:00pm","8:30pm","9:00pm","9:30pm","10:00pm","10:30pm","11:00pm","11:30pm"]
  	schedule_normalized = []
	inviter.calendar.schedule[schedule_day].each do |time, status|
		if status == "free"
			standard_time = (Time.parse(time) + @current_user.time_zone_offset.minutes).strftime("%-I:%M%p").downcase
			schedule_normalized.push(standard_time)
		end
	end

	# takes the order of the arr and compares it to that 
	sorted_schedule = schedule_normalized.sort_by &arr.method(:index)
	sorted_schedule
	
  end

	

	
	
end





# {
# 	"2020-4-1" : {
# 		"8:00AM" : "call with andrew", 
# 		"9:00AM" : "free" 
# 	}, 
# }


# Backend 
# - know current time
# - figure out minimum time to show for today 
# - check if today and tomorrow are filled 
# - if yes, send the times that are taken in the array

# receiving 
# - check what times are selected and save it 


# {
# 	"8:00am",  #0
# 	"8:30am",  #1
# 	"9:00am",  #2
# 	"9:30am",  #3
# 	"10:00am", #4
# 	"10:30am", #5
# 	"11:00am", #6
# 	"11:30am", #7
# 	"12:00pm", #8
# 	"12:30pm", #9
# 	"1:00pm",  #10
# 	"1:30pm",  #11
# 	"2:00pm",  #12
# 	"2:30pm",  #13
# 	"3:00pm",  #14
# 	"3:30pm",  #15
# 	"4:00pm",  #16
# 	"4:30pm",  #17
# 	"5:00pm",  #18
# 	"5:30pm",  #19
# 	"6:00pm",  #20
# 	"6:30pm",  #21
# 	"7:00pm",  #22
# 	"7:30pm",  #23
# 	"8:00pm",  #24
# 	"8:30pm",  #25
# 	"9:00pm",  #26
# 	"9:30pm",  #27
# 	"10:00pm", #28
# 	"10:30pm", #29
# 	"11:00pm", #30
# 	"11:30pm", #31	
# }










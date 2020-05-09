class Api::V1::CalendarsController < ApplicationController
	  before_action :authenticate_with_token!, only: [:get_calendar, :set_calendar, :update_calendar]

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












	def get_calendars 
		# did the user select times for today or tomorrow 
		date1 = Time.current.utc.to_date.to_s

		# need to check if date set is the same as date now from front end 

		if @current_user.calendar
			#check if todays date is the same
			if @current_user.calendar.schedule["todays_date"] === date1
				
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

				render json: { 
					is_success: true, 
					has_calendar: true, 
					todays_schedule: todays_schedule_normalized,
					tomorrows_schedule: tomorrows_schedule_normalized
				}, status: :ok

			# check if tomorrows date in db is todays date	
			elsif @current_user.calendar.schedule["tomorrows_date"] === date1

				tomorrows_schedule_normalized = {}
				@current_user.calendar.schedule["tomorrows_schedule"].each do |time, status|
					standard_time = (Time.parse(time) + @current_user.time_zone_offset.minutes).strftime("%-I:%M%p").downcase
					tomorrows_schedule_normalized[standard_time] = status 
				end

				@current_user.calendar.todays_date =  todays_date.to_date,
				tomorrows_date =  tomorrows_date.to_date
				@current_user.calendar.schedule["todays_schedule"] = @current_user.calendar.schedule["tomorrows_schedule"]
				@current_user.calendar.schedule["tomorrows_schedule"] = {}

				render json: { 
					is_success: true, 
					has_calendar: true, 
					todays_schedule: tomorrows_schedule_normalized,
					tomorrows_schedule: {}
				}, status: :ok

			# else saved calendar is old 
			else
				render json: { is_success: true, has_calendar: true, todays_schedule: {}, tomorrows_schedule: {} }, status: :ok
			end 


		else
 			render json: { is_success: true, has_calendar: true, todays_schedule: {}, tomorrows_schedule: {} }, status: :ok
		end


	end


	def set_calendars
		todays_date = Time.current.utc
		tomorrows_date = todays_date + 1.day 
		calendar_set_before = @current_user.calendar

		#need to check if the today coming in is actually one of the two saved dates 
		# if today is the same, use same data 
		# if tomorrows saved data is the same as today's date switch tomorrows to today and clear tomorrows data 
		# if none of the dates coincide, erase all data and set 
		if calendar_set_before
			# get users current date and saved date - this can be different from utc time 
			user_right_now = (todays_date + @current_user.time_zone_offset.minutes).to_date
			last_saved_today = @current_user.calendar.schedule["todays_date"] 

			if user_right_now != last_saved_today 
				render json: { is_success: false, run_get_calendar: true }, status: :ok
			end
			
		end

		todays_schedule_updated = params[:todays_schedule]
		todays_schedule_utc = {}
		todays_schedule_updated.each do |obj| #{"id"=>1, "time"=>"8:00am", "status"=>"dont show"}
			utc_time = (Time.parse(obj["time"]) - @current_user.time_zone_offset.minutes).strftime("%-I:%M%p").downcase
			todays_schedule_utc[utc_time] = obj["status"]
		end

		tomorrows_schedule_updated = params[:tomorrows_schedule]
		tomorrows_schedule_utc = {}
		tomorrows_schedule_updated.each do |obj|
			utc_time = (Time.parse(obj["time"]) - @current_user.time_zone_offset.minutes).strftime("%-I:%M%p").downcase
			tomorrows_schedule_utc[utc_time] = obj["status"]
		end


		if calendar_set_before
			@current_user.calendar.schedule = {				
				todays_date: todays_date.to_date,
				tomorrows_date: tomorrows_date.to_date,
				todays_schedule: todays_schedule_utc,
				tomorrows_schedule: tomorrows_schedule_utc
			}
			
		else
			Calendar.new(user: @current_user, schedule: {
				todays_date: todays_date.to_date,
				tomorrows_date: tomorrows_date.to_date,
				todays_schedule: todays_schedule_utc,
				tomorrows_schedule: tomorrows_schedule_utc
			})

		end

		if @current_user.calendar.save 
			render json: { is_success: true }, status: :ok
		else
			render json: { is_success: false }, status: :ok
		end
	end

	def view_calendar_for_booking 
	end


	def update_calendar_on_booking 
		# needs to update two calendars 
		# receive token, user id, and time 
		# update invitation time 
		sent_invitation_user = params

		invitation = Invitation.find_by(user_id: 155, invitation_recipient_id: @current_user.id)

		
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










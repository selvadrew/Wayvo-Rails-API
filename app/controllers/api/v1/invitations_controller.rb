class Api::V1::InvitationsController < ApplicationController
  before_action :authenticate_with_token!, only: [:all_user_invitation_data, :show_friends_calendar]

  def all_user_invitation_data
  	#invitations I received - For you 
  	#calls booked - Upcoming 
  	#invitations I sent - For friends 

  	invitations_sent = @current_user.invitations
  	invitations_received = @current_user.invitations_received

  	# includes objects from both sent and received invitations 
  	upcoming_booked_calls = []

  	waiting_for_me = []
  	invitations_received.each do |inv|
  		if inv.scheduled_call == nil 
  			waiting_for_me.push(invitation_object(inv))
  		elsif inv.scheduled_call > (Time.now - 1.hours)
  			upcoming_booked_calls.push(invitation_object(inv))
  		end
  	end
  	
  	waiting_for_friends = []
  	invitations_sent.each do |inv|
  		if inv.scheduled_call == nil 
  			waiting_for_friends.push(invitation_object(inv))
  		elsif inv.scheduled_call > (Time.now - 1.hours)  
  			upcoming_booked_calls.push(invitation_object(inv))
  		end
  	end

  	# get all non users that received a text from current user 
  	waiting_for_texted_friends = TextInvitation.all.where(user_id: @current_user.id, is_user: false).where('created_at >= :five_days_ago', :five_days_ago => Time.now.utc - 5.days).pluck(:contact).uniq

  	render json: { is_success: true, waiting_for_me: waiting_for_me, upcoming_booked_calls: upcoming_booked_calls, waiting_for_friends: waiting_for_friends, waiting_for_texted_friends: waiting_for_texted_friends}

  end


  def show_friends_calendar 
  	# receive id 
  	# get today and tomorrow- if not show false 
  	# if i want to see my friends calendar - i need to get their calendar and change it to my time zone 
  	# after selecting a time, it would need to change back to utc prob
  	invitation = Invitation.find_by(id: params[:invitation_id], user_id: params[:user_id])
  	@inviter = User.find_by(id: params[:user_id])
  	date_today_in_utc = Time.current.utc
  
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

	  	render json:{ is_success: true, todays_dates: todays_schedule_normalized, tomorrows_dates: tomorrows_schedule_normalized, updated_at: invitation.updated_at }, status: :ok

	else 
		render json:{ is_success: false }, status: :ok
  	end

  end 


  def book_friends_calendar 
  	### before doing this, need to double check that in the above method, the current user selecting, doesnt already have a booked call during that time

  	# params day will be today or tomorrow 
  	# params time selected 
  	# params updated_at 
  	# params invitation_id 

  	# if current invitation object is greater than params updated at, send success false so user can reload show_friends_calendar 
  	# use today/tomorrow and time selected to create scheduled_at field 
  	# update both users calendars  


  end



  private

  def invitation_object(inv)
  	if inv.user_id == @current_user.id 
  		user = User.find_by_id(inv.invitation_recipient_id)
  	else
  		user = User.find_by_id(inv.user_id)
  	end
  	
  	scheduled_call = inv.scheduled_call
  	if scheduled_call 
  		# need to find out the standardized time and if its today or tomorrow 
  		scheduled_call = scheduled_call + @current_user.time_zone_offset.minutes
  	end

  	inv = { invitation_id: inv.id, user_id: user.id, fullname: user.fullname, phone_number: user.phone_number, scheduled_call: scheduled_call }
  	inv

  end

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
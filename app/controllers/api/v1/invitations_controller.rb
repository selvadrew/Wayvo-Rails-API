class Api::V1::InvitationsController < ApplicationController
  before_action :authenticate_with_token!, only: [:all_user_invitation_data, :show_friends_calendar, :book_friends_calendar]

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

  	sorted_upcoming_booked_calls = upcoming_booked_calls.sort_by { |hsh| hsh[:scheduled_call] }


  	# get all non users that received a text from current user 
  	# used uniq at the end because a user can have multiple phone numbers that a text was sent to, just get one 
  	waiting_for_texted_friends = TextInvitation.all.where(user_id: @current_user.id, is_user: false).where('created_at >= :five_days_ago', :five_days_ago => Time.now.utc - 5.days).pluck(:contact).uniq.map { |fullname| {fullname: fullname, invitation_id: fullname}}  

  	render json: { is_success: true, waiting_for_me: waiting_for_me, upcoming_booked_calls: sorted_upcoming_booked_calls, waiting_for_friends: waiting_for_friends, waiting_for_texted_friends: waiting_for_texted_friends}

  end




  private

  def invitation_object(inv)
  	if inv.user_id == @current_user.id 
  		user = User.find_by_id(inv.invitation_recipient_id)
  	else
  		user = User.find_by_id(inv.user_id)
  	end
  	
  	scheduled_call = inv.scheduled_call
  	scheduled_call_utc = nil 
  	scheduled_call_user_tz = nil 
  	time_user_tz = nil 
  	day = "" 
  	date_today_user_tz = (Time.current.utc + @current_user.time_zone_offset.minutes).to_date 
  	tomorrow_date_user_tz = date_today_user_tz + 1.day 

  	if scheduled_call 
  		# need to find out the standardized time and if its today or tomorrow 
  		scheduled_call_utc = scheduled_call 
  		scheduled_call_user_tz = scheduled_call + @current_user.time_zone_offset.minutes
  		time_user_tz = scheduled_call_user_tz.strftime("%-I:%M%p").downcase
  		
  		if date_today_user_tz == scheduled_call_user_tz.to_date 
  			day = "today"
  		elsif tomorrow_date_user_tz == scheduled_call_user_tz.to_date
  			day = "tomorrow"
  		end
  	end

  	inv = { 
	  		invitation_id: inv.id, 
	  		user_id: user.id, 
	  		fullname: user.fullname, 
	  		first_name: user.first_name, 
	  		phone_number: user.phone_number, 
	  		scheduled_call: scheduled_call, 
	  		scheduled_call_utc: scheduled_call_utc, 
	  		scheduled_call_user_tz: scheduled_call_user_tz, 
	  		time_in_user_tz: time_user_tz, 
	  		day: day,
	  		ios: user.iOS
  		}

  	inv

  end




end
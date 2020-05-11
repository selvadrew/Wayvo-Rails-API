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

  	# get all non users that received a text from current user 
  	waiting_for_texted_friends = TextInvitation.all.where(user_id: @current_user.id, is_user: false).where('created_at >= :five_days_ago', :five_days_ago => Time.now.utc - 5.days).pluck(:contact).uniq

  	render json: { is_success: true, waiting_for_me: waiting_for_me, upcoming_booked_calls: upcoming_booked_calls, waiting_for_friends: waiting_for_friends, waiting_for_texted_friends: waiting_for_texted_friends}

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




end
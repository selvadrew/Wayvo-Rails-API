class Api::V1::InvitationsController < ApplicationController
  before_action :authenticate_with_token!, only: [:all_user_invitation_data, :show_friends_calendar, :book_friends_calendar, :time_to_catch_up]

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

  	#check if this user has sent invitations before 
    new_user = true  
    if invitations_sent || TextInvitation.all.where(user_id: @current_user.id).count > 0 
      new_user = false 
    end


    render json: { is_success: true, waiting_for_me: waiting_for_me, upcoming_booked_calls: sorted_upcoming_booked_calls, waiting_for_friends: waiting_for_friends, waiting_for_texted_friends: waiting_for_texted_friends, new_user: new_user}

  end


  def time_to_catch_up
    # get merged contacts 
    # iterate through all
    # if it has a relationship - iterate through that relationships numbers
    #  check if text/user invitation exists  
    # c1 do nothing = open invitation exists - can be sent text with is user false or sent/received notification invitation 
    # c2 two cases, do something for one = scheduled call - check if its time to send now 
    # c3 do something - nothing has been done 
    # needs to be called whenever the contact relationship is changed or when user accepts an invitation - shoow spinner on plus sign 

    #text send(start with false) - if one of the numbers became a user, set to true. if it doesnt exist, set to true. 
    # if text send and can_send are true, add number to array 

    # get merged contacts 
    merged_contacts = @current_user.phone_contacts + @current_user.username_contacts

    contacts_to_catch_up_with = []

    merged_contacts.each do |contact|
      if contact["relationship_days"] > 0 && contact["relationship_days"] < 100 
        can_send = true # checks for user 
        text_sent = true 
        relationship_days = contact["relationship_days"]

        contact["phoneNumbers"].each do |phoneNumber|
          number = phoneNumber["number"] 
          formatted_number = number.delete("^0-9")
          legal_format = false 
          if formatted_number.length == 10
            #fullname and formatted_number are correct 
            legal_format = true 
          elsif formatted_number.length == 11 && formatted_number.first.to_i == 1
            formatted_number = formatted_number[1..-1] #takes second character to the last from the string 
            legal_format = true 
          end

          if legal_format # only american and canadian numbers are supported right now 
            #do all the work here 
            user = User.find_by(phone_number: formatted_number)
            if user
              @invitation_sent = Invitation.find_by(user_id: @current_user.id, invitation_recipient_id: user.id) 
              if @invitation_sent
                if @invitation_sent.scheduled_call == nil 
                  can_send = false #if theres an open invitation, do nothing
                elsif @invitation_sent.scheduled_call.to_date + relationship_days.days > Time.now.to_date 
                  can_send = false #if the scheduled call + days remaining is greater than now, cant send 
                end
              end

              @invitation_received = Invitation.find_by(user_id: user.id, invitation_recipient_id: @current_user.id) 
              if @invitation_received
                if @invitation_received.scheduled_call == nil 
                  can_send = false #if theres an open invitation, do nothing
                elsif @invitation_received.scheduled_call.to_date + relationship_days.days > Time.now.to_date 
                  can_send = false #if the scheduled call + days remaining is greater than now, cant send 
                end
              end

            else # not a user yet 
              received_text = TextInvitation.find_by(phone_number: formatted_number, is_user: false)
              if received_text
                text_sent = false #dont send anything in this case 
              end 
            end

          end

        end

        if can_send && text_sent 
          contacts_to_catch_up_with.push(contact)
        end

      end
    end

    render json: { is_success: true, contacts_to_catch_up_with: contacts_to_catch_up_with } 

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
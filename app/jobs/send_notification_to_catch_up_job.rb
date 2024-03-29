class SendNotificationToCatchUpJob < ApplicationJob
  queue_as :default

  def perform(current_user, name_and_number)
  	require 'fcm'
    fcm = FCM.new("AAAAAOXsHmg:APA91bFeO5xEEP3Zqkg1Ht3ocwzphQ9uEFGdUHHbRsGHAaVSqEXdJWAUo026ENDbFKJ6Sxy7UFRBYmm-ZH6NOkBGRbZvWhWtm8beW0lRtJivIdoExzfkiYk5QWj98kfTB9-sE4gD6oX-")
    registration_ids = []
    
    # this was used when manually sending invite from front end ###################
  	name_and_number = JSON.parse(name_and_number) 
  	
  	# clean data to remove brackets and hyphens
  		#figure out if legit number - 10 digits or 11 digits but starts with 1 
  	
  	name_and_number.each do |name_and_number| 
  		fullname = name_and_number["fullname"]
  		formatted_number = name_and_number["phoneNumber"].delete("^0-9")
  		run = false 

  		if formatted_number.length == 10
  			#fullname and formatted_number are correct 
  			run = true 
  		elsif formatted_number.length == 11 && formatted_number.first.to_i == 1
  			formatted_number = formatted_number[1..-1] #takes second character to the last from the string 
  			run = true 
  		end

  		if current_user.first_name.last == "s"
			name_ownership = "'"
		else
			name_ownership = "'s"
		end


  		if run  
  			number = formatted_number.strip

  			user = User.find_by(phone_number: number)
  			if user 
				can_send = true 

				@invitation_sent = Invitation.find_by(user_id: current_user.id, invitation_recipient_id: user.id) 
				if @invitation_sent
					if @invitation_sent.scheduled_call == nil 
						can_send = false #if theres an open invitation, do nothing
					elsif @invitation_sent.scheduled_call > (Time.now - 1.hours)
						can_send = false #if theres an upcoming scheduled call, do nothing 
					end
				end

				@invitation_received = Invitation.find_by(user_id: user.id, invitation_recipient_id: current_user.id) 
				if @invitation_received
					if @invitation_received.scheduled_call == nil 
						can_send = false #if theres an open invitation, do nothing
					elsif @invitation_received.scheduled_call > Time.now
						can_send = false #if theres an upcoming scheduled call, do nothing 
					end
				end

				
				
				if can_send
					Invitation.create(user_id: current_user.id, invitation_recipient_id: user.id)
					
					##### insert notification code ##### 
					# Andrew wants to catch up with you! - Open your invitation here to view and join Andrew’s calendar 

					@notification = {
          				title: "#{current_user.first_name} wants to catch-up with you!",
          				body: "Open your invitation here to view and join #{current_user.first_name}#{name_ownership} Calendar",
          				sound: "default"
        			} 

					registration_ids << user.firebase_token

    				options = { notification: @notification, priority: 'high', data: { upcoming: true } }
    				response = fcm.send(registration_ids, options)

				end

			else# could send reminder in the future 
				twilio_formatted_number = "+1" + number 

				#number is not in the "dont text me" list 
				said_stop = Stop.find_by(number: twilio_formatted_number)
				#check if already invited by text 
				already_texted = TextInvitation.find_by(user_id: current_user.id, phone_number: number)

				unless said_stop 
					unless already_texted
						TextInvitation.create(user_id: current_user.id, phone_number: number, contact: fullname)

						##### text content #####
						account_sid = ENV.fetch("TWILIO_ACCOUNT_SID") { Rails.application.secrets.TWILIO_ACCOUNT_SID } 
						auth_token = ENV.fetch("TWILIO_AUTH_TOKEN") { Rails.application.secrets.TWILIO_AUTH_TOKEN }   

						begin 
						@client = Twilio::REST::Client.new account_sid, auth_token

						message = @client.messages.create(
						  body: "Howdy! #{current_user.fullname} wants to catch-up with you over a phone call. Choose a time that works for you from #{current_user.first_name}#{name_ownership} calendar in the Wayvo App - www.onelink.to/wayvo.\n\nThe Wayvo app helps you schedule weekly or monthly 1-on-1 phone calls with all the people you care about.",
						  to: twilio_formatted_number,
						  from: "+16474902706" 
						)

						rescue Twilio::REST::RestError => e
							puts e 
						end

						# puts message.sid
						##### text content #####

					end
				end


			end
	  	end# if run 
  	end
  end
end
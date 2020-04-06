class SendNotificationToCatchUpJob < ApplicationJob
  queue_as :default

  def perform(current_user, phone_numbers)
  	
  	# clean data to remove brackets and hyphens
  		#figure out if legit number - 10 digits or 11 digits but starts with 1 
  	cleaned_numbers = []
  	phone_numbers.each do |number| 
  		formatted_number = number.delete("^0-9")
  		
  		if formatted_number.length == 10
  			cleaned_numbers << formatted_number
  		elsif formatted_number.length == 11 && formatted_number.first.to_i == 1
  			cleaned_numbers << formatted_number[1..-1] #takes second character to the last from the string 
  		end

  	end

  	# figure out if sending a notification or a text 
	puts cleaned_numbers

	cleaned_numbers.each do |number|
		number.strip!
		user = User.find_by(phone_number: number)
		if user 
			open_invitation = Invitation.find_by(user_id: current_user.id, invitation_recipient_id: user.id, scheduled_call: nil) 
			
			#if theres an open invitation, do nothing 
			unless open_invitation
				Invitation.create(user_id: current_user.id, invitation_recipient_id: user.id)
				puts "send notification"
			end

		else
			twilio_formatted_number = "+1" + number 

			#number is not in the "dont text me" list 
			said_stop = Stop.find_by(number: twilio_formatted_number)
			#check if already invited by text 
			already_texted = TextInvitation.find_by(user_id: current_user.id, phone_number: number)

			unless said_stop 
				unless already_texted
					TextInvitation.create(user_id: current_user.id, phone_number: number)
					puts "send text"
				end
			end

		end
	end




	# Step 1
	# Check if previous invite exists with null in scheduled time 

	# Step 2 
	# Check that they are not on the STOP list 

	# Step 3
	# check if user exists 
	# send notification or text message 


	# step 1 
	#check if the user exists 
	# step 2 




  end

end
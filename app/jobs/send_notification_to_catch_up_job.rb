class SendNotificationToCatchUpJob < ApplicationJob
  queue_as :default

  def perform(current_user, name_and_number)
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


  		if run  
  			number = formatted_number.strip

  			user = User.find_by(phone_number: number)
  			if user 
				open_invitation = Invitation.find_by(user_id: current_user.id, invitation_recipient_id: user.id, scheduled_call: nil) 
				
				#if theres an open invitation, do nothing 
				# could send reminder in the future 
				unless open_invitation
					Invitation.create(user_id: current_user.id, invitation_recipient_id: user.id)
					puts "send notification" 
					########## insert notification code 
				end

			else
				twilio_formatted_number = "+1" + number 

				#number is not in the "dont text me" list 
				said_stop = Stop.find_by(number: twilio_formatted_number)
				#check if already invited by text 
				already_texted = TextInvitation.find_by(user_id: current_user.id, phone_number: number)

				unless said_stop 
					unless already_texted
						TextInvitation.create(user_id: current_user.id, phone_number: number, contact: fullname)
						puts "send text"
						########## insert text code
					end
				end

			end
	  	end
  	end

	# puts cleaned_numbers 
	# {:fullname=>"John Appleseed", :formatted_number=>"8885555512"}


	# # send text, send notification, or do nothing 
	# cleaned_numbers.each do |name_and_number|


	# 	number.strip!
	# 	user = User.find_by(phone_number: number)
	# 	if user 
	# 		open_invitation = Invitation.find_by(user_id: current_user.id, invitation_recipient_id: user.id, scheduled_call: nil) 
			
	# 		#if theres an open invitation, do nothing 
	# 		unless open_invitation
	# 			Invitation.create(user_id: current_user.id, invitation_recipient_id: user.id)
	# 			puts "send notification" 
	# 			# insert notification code 
	# 		end

	# 	else
	# 		twilio_formatted_number = "+1" + number 

	# 		#number is not in the "dont text me" list 
	# 		said_stop = Stop.find_by(number: twilio_formatted_number)
	# 		#check if already invited by text 
	# 		already_texted = TextInvitation.find_by(user_id: current_user.id, phone_number: number)

	# 		unless said_stop 
	# 			unless already_texted
	# 				TextInvitation.create(user_id: current_user.id, phone_number: number)
	# 				puts "send text"
	# 				# insert text code

	# 			end
	# 		end

	# 	end
	# end


  end

end
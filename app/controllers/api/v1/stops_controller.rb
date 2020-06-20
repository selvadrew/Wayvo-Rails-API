class Api::V1::StopsController < ApplicationController

	def incoming_sms
		IncomingText.create(
	      message_sid: params[:MessageSid],
	      to: params[:To],
	      from: params[:From], 
	      body: params[:Body], 
	      sms_status: params[:SmsStatus], 
	      num_segments: params[:NumSegments],
	      num_media: params[:NumMedia]
      	)

		from_number = params[:From]
		message = params[:Body]

		if message.downcase.include? "stop"
			Stop.create(number: from_number, message: message)

			### Looks like twilio handles this on their own 
			# ##### text content #####
			# account_sid = ENV.fetch("TWILIO_ACCOUNT_SID") { Rails.application.secrets.TWILIO_ACCOUNT_SID } 
			# auth_token = ENV.fetch("TWILIO_AUTH_TOKEN") { Rails.application.secrets.TWILIO_AUTH_TOKEN }   

			# @client = Twilio::REST::Client.new account_sid, auth_token

			# message = @client.messages.create(
			#   body: "You will no longer receive text messages from Wayvo.",
			#   to: from_number,
			#   from: "+16474902706"
			# )  
		end

	end
	
end

class Api::V1::StopsController < ApplicationController

	def incoming_sms
		from_number = params[:From]
		message = params[:Body]

		if message.downcase.include? "stop"
			Stop.create(number: from_number, message: message)
		end

	end
	
end

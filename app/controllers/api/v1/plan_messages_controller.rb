class Api::V1::PlanMessagesController < ApplicationController
	before_action :authenticate_with_token!

	def create
		new_message = PlanMessage.new(content: params[:content], plan_id: params[:plan_id], user_id: current_user.id)
		
		if new_message.save 
			render json: { is_success: true }, status: :ok
		else 
			render json: { is_success: false }, status: :ok
		end

	end

end


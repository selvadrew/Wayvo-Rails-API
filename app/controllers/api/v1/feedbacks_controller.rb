class Api::V1::FeedbacksController < ApplicationController
	before_action :authenticate_with_token!

	def create

		@feedback = current_user.feedbacks.build
		@feedback.description = params[:description]


		if @feedback.save
      		render json: { is_success: true}, status: :ok
    	else
      		render json: { is_success: false}, status: 404
    	end 

	end
		
end














class Api::V1::ProgramGroupMembersController < ApplicationController
  before_action :authenticate_with_token!

  def request_to_join_program
    @user = User.find_by(access_token: params[:access_token])
    @program = Program.find_by(id: params[:programId])


    #check if user is already enrolled in a program in the database 
    exists = ProgramGroupMember.find_by(user_id: @user.id)
    if exists 
      exists.program_id = @program.id 
      @user.submitted = true
      @user.enrollment_date = params[:startYear]

      if exists.save && @user.save 
        render json: {is_success: true }, status: :ok
      else
        render json: { is_success: false}, status: :ok
      end

    else
      program_member = ProgramGroupMember.new(program_id: @program.id, user_id: @user.id)
      @user.submitted = true
      @user.enrollment_date = params[:startYear]

      if program_member.save && @user.save 
        render json: {is_success: true}, status: :ok
      else
        render json: { is_success: false}, status: :ok
      end         

    end #exists
  end #def

  def get_program_group
    if current_user.verified 
      program = ProgramGroupMember.find_by(user_id: current_user.id)
      program_obj = program.program
      program_details = [{id: program_obj.id, value: program_obj.program_name, type: 0  }]
      university_name = program.program.university.university_name

      if program 
        render json: {is_success: true, program_details: program_details, university_name: university_name }, status: :ok
      else
        render json: { is_success: false}, status: :ok
      end
      
    else
      render json: { is_success: false}, status: :ok
    end


  end


end 
class Api::V1::UniversitiesController < ApplicationController
  before_action :authenticate_with_token!, only: [:request_to_join_program]

  def get_university
    @universities = University.all

    universities_data = []
    @universities.each do |uni| 
      # details = []
      # details.push(value: uni.university_name, id: uni.id)
      details =  {value: uni.university_name, id: uni.id}
      universities_data << details
    end
    universities_data.sort_by! {|obj| obj[:value]}

    if @universities.empty? 
      render json: { is_success: false}, status: :ok
    else  
      render json: {universities: universities_data, is_success: true}, status: :ok
    end
  end



  def get_program
    @university_id = params[:id]
    @programs = Program.all.where(university_id: @university_id)

    programs_data = []
    @programs.each do |prog| 
      # details = []
      # details.push(value: uni.university_name, id: uni.id)
      details =  {value: prog.program_name, id: prog.id}
      programs_data << details
    end
    programs_data.sort_by! {|obj| obj[:value]}

    if @programs.empty? 
      render json: { is_success: false}, status: :ok
    else  
      render json: {programs: programs_data, is_success: true}, status: :ok
    end
  end





end







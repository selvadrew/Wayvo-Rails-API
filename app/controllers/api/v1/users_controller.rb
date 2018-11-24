class Api::V1::UsersController < ApplicationController
  before_action :authenticate_with_token!, only: [:logout, :check_username, :add_phone_number, :get_phone_number]

  def facebook
    if params[:facebook_access_token]
      graph = Koala::Facebook::API.new(params[:facebook_access_token])
      user_data = graph.get_object("me?fields=name,email,id,picture")

      user = User.find_by(email: user_data['email'])
      if user
        user.generate_authentication_token
        user.save
        render json: user, status: :ok
      else
        user = User.new(
                    fullname: user_data['name'],
                    email: user_data['email'],
                    uid: user_data['id'],
                    provider: 'Facebook',
                    image: user_data['picture']['data']['url'],
                    password: Devise.friendly_token[0,20]
                )
        user.generate_authentication_token

        if user.save
          render json: {
            access_token: user.access_token, 
            phone_number: user.phone_number, 
            fullname: user.fullname, 
            username: user.username
          }, 
            status: :ok
        else
          render json: { error: user.errors, is_success: false, where: "here1"}, status: 422
        end
      end
    else
      render json: { error: "Invalid Facebook Token", is_success: false}, status: :unprocessable_entity
    end
  end

  def email_signup
    if params[:email] && params[:password]
      user = User.find_by(email: params[:email])

      if user
        if user.provider
          render json: { error: "You already used this email when you logged in with Facebook. Go back and press 'Continue with Facebook'.", is_success: false}, status: 422 
        else
          render json: { error: "An account has already been created with this email. Please log in.", is_success: false}, status: 422 
        end 
      else
        user = User.new(
                    email: params[:email].downcase,
                    password: params[:password]
                )
        user.generate_authentication_token
        if user.save
          render json: {access_token: user.access_token}, status: :ok
        else
          render json: { error: "Sorry, something went wrong.", is_success: false }, status: 422
        end
      end
    else 
      render json: { error: "Sorry, something went wrong.", is_success: false }, status: 422
    end
  end

  def email_login 
    if params[:email] && params[:password]
      user = User.find_by(email: params[:email])

      if user && user.authenticate(params[:password]) 
        render json: {
            access_token: user.access_token, 
            phone_number: user.phone_number, 
            fullname: user.fullname, 
            username: user.username
          }, 
            status: :ok
      else
        render json: { is_success: false }, status: 422
      end
    else 
      render json: { is_success: false }, status: 422
    end
  end



  def store_firebase_token
    user = User.find_by(access_token: params[:access_token])
    user.firebase_token = params[:firebase_token]
    if user.save 
      render json: { firebase_token: user.firebase_token, is_success: true }, status: :ok
    else 
      render json: { is_success: false }, status: :ok
    end
  end

  def save_fullname
    user = User.find_by(access_token: params[:access_token])
    user.fullname = params[:fullname].downcase
    user.fullname = user.fullname.titleize

    if user.save 
      render json: { fullname: user.fullname, is_success: true }, status: :ok
    else 
      render json: { is_success: false }, status: :ok
    end
  end



  def logout
    user = User.find_by(access_token: params[:access_token])
    user.generate_authentication_token
    user.firebase_token = nil 
    user.save
    render json: { is_success: true}, status: :ok
  end

  def check_username 

    #######
    # no capitals, spaces, or extra characters other than dot and underscore 

    user = User.find_by(access_token: params[:access_token])
    proposed_username = params[:username].downcase

    username_exists = User.find_by(username: proposed_username)
    user.username = proposed_username

    if username_exists 
      render json: { error: 1, is_success: false}, status: 404
      
    elsif user.save
      render json: { is_success: true, username: user.username }, status: :ok

    else
      render json: { error: 2, is_success: false}, status: 404
    end   
  end


  def add_phone_number 

    user = User.find_by(access_token: params[:access_token])
    user.phone_number = params[:phone_number]

    if user.save
      render json: { is_success: true}, status: :ok
    else
      render json: { error: "There was an error saving your phone number.", is_success: false}, status: 404

    end   
  end


  def get_phone_number

    user = User.find_by(access_token: params[:access_token])
    user.iOS = params[:ios]

    if user.phone_number && user.save 
      render json: {is_success: true, fullname: user.fullname, phone_number: user.phone_number, username: user.username }
    else
      render json: {is_success: false}, status: 404
    end
  end


end


























class Api::V1::UsersController < ApplicationController
  before_action :authenticate_with_token!, only: [:delete_contact, :save_username_contact, :save_phone_contacts, :get_contacts_from_db, :logout, :check_username, :add_phone_number, :get_phone_number, :send_invite_to_catch_up, :save_time_zone, :save_username_contact]

  require 'sendgrid-ruby'
  include SendGrid
  require 'twilio-ruby'

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
    user.fullname = params[:fullname].downcase.titleize
    user.first_name = params[:first_name].downcase.titleize
    user.last_name = params[:last_name].downcase.titleize

    user.verified = false
    user.submitted = false

    if user.save 
      render json: { fullname: user.fullname, first_name: user.first_name, last_name: user.last_name, is_success: true }, status: :ok
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
      render json: {
        is_success: true, 
        fullname: user.fullname, 
        phone_number: user.phone_number, 
        username: user.username, 
        instagram: user.instagram || "false",
        snapchat: user.snapchat || "false",
        twitter: user.twitter || "false",
        #firebase_token: user.firebase_token, gonna call firebase every time app opens up for now 
        enrollment: user.enrollment_date || "false", 
        verified: user.verified,
        submitted: user.submitted, 
        user_id: user.id
      }
    else
      render json: {is_success: false}, status: 404
    end
  end


  def get_uni_requests
    if current_user.id == 2 || current_user.id == 40 || current_user.username == "admin" 
      users = User.all.where(submitted: true, verified: false).order(updated_at: :desc).pluck(:id, :username, :fullname,).map { |id, username, fullname| {id: id, username: username, fullname: fullname}}
      if users 
        render json: {is_success: true, users: users }, status: 404
    else
        render json: {is_success: false}, status: 404
      end
    end
  end

  def uni_request_update
    if current_user.id == 2 || current_user.id == 40 || current_user.username == "admin" 
      require 'fcm'
      fcm = FCM.new("AAAAAOXsHmg:APA91bFeO5xEEP3Zqkg1Ht3ocwzphQ9uEFGdUHHbRsGHAaVSqEXdJWAUo026ENDbFKJ6Sxy7UFRBYmm-ZH6NOkBGRbZvWhWtm8beW0lRtJivIdoExzfkiYk5QWj98kfTB9-sE4gD6oX-")

      @user = User.find_by(id: params[:id])
      if params[:status]
        @user.verified = true 
        @notification = {
          title: "You're verified!",
          body: "Go start a plan with one of your groups!",
          sound: "default"
        }
      else 
        @user.submitted = false 
        @notification = {
          title: "Please re-submit your photo to get verified",
          body: "Sorry, looks like your photo is invalid. We understand you may be uncomfortable taking a selfie but it's the only way we can keep everyone safe from people who shouldn't be on the platform.",
          sound: "default"
        }

        if @user.custom_group_members
          @user.custom_group_members.last.destroy
        end
      end

      if @user.save 
        firebase_token = [@user.firebase_token]
        registration_ids = firebase_token
        options = {notification: @notification, priority: 'high'}
        response = fcm.send(registration_ids, options)
      end

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
          render json: {access_token: user.access_token, new_user: true}, status: :ok
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
            new_user: false,
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


  def verify_with_email_code
    user = User.find_by(access_token: params[:access_token])
    if user.email_code == params[:email_code].to_i
      if user.phone_number && user.fullname && user.username 
        #login
        render json: {
            is_success: true,
            new_user: false,
            access_token: user.access_token, 
            phone_number: user.phone_number, 
            fullname: user.fullname, 
            username: user.username,
            university_id: user.university_id,
            university_name: user.university.university_name
          }, 
            status: :ok
      else
        #signup
         render json: {is_success: true, access_token: user.access_token, new_user: true, university_id: user.university_id, university_name: user.university.university_name}, status: :ok
      end

    else
      render json: { is_success: false, error: "Incorrect code" }, status: :ok
    end
  end

  def send_email_code
    email = params[:email].downcase

    EmailTry.create(email: email)
    user = User.find_by(email: email)
    correct_email = false 
    new_user = true 
    send_email = false 

    if user 
      user.generate_email_code 
      user.save
      new_user = false 
      send_email = true 
      message = "back"

    else
      #school email exists 
      University.where.not(email: nil).each do |uni|
        email_handle = uni.email
        length = email_handle.length
        if email.last(length).include? email_handle
          correct_email = true 
          send_email = true 
          message = "to Wayvo"

          #create user 
          user = User.new(email: email)
          user.generate_authentication_token
          user.generate_email_code 
          user.university_id = uni.id
          if !user.save
            send_email = false 
            render json: { error: "Sorry, something went wrong.", is_success: false }, status: 422
          end
          break
        end
      end

      #school email doesnt exist 
      if !correct_email
        render json: {error: "Double check your email. If it's correct, we don't support your school yet. Sorry :("}, status: :ok
      end
    end

    if send_email
      from = SendGrid::Email.new(email: 'hello@wayvo.app')
      to = SendGrid::Email.new(email: email)
      subject = 'Wayvo Verification Code'
      content = SendGrid::Content.new(
        type: 'text/plain', 
        value: "Welcome #{message}. Your verification code is: #{user.email_code}"
        )
      mail = SendGrid::Mail.new(from, subject, to, content)

      ##sg = SendGrid::API.new(api_key: ENV['SENDGRID_API_KEY'])
      sg = SendGrid::API.new(api_key: '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')
      ##response = sg.client.mail._('send').post(request_body: mail.to_json)
      
      #should check status code?
      #puts response.status_code
      puts user.email_code

      render json: { is_success: true, access_token: user.access_token, new_user: new_user }, status: :ok
    end
  end


  def send_sms_code
    phone_number = params[:phone_number]
    user = User.find_by(phone_number: phone_number) 
    new_user = true  
    send_sms = true    
    message = "to Wayvo"
    
    if user && user.username  
      user.generate_email_code 
      new_user = false 
      message = "back"
    else 
      #create user 
      unless user 
        user = User.new(phone_number: phone_number, phone_contacts: [], username_contacts: [] )
      end
      user.generate_authentication_token
      user.generate_email_code 
    end

    if !user.save
      send_sms = false 
      render json: { error: "Sorry, something went wrong.", is_success: false }, status: 422
    end

    if send_sms
      account_sid = ENV.fetch("TWILIO_ACCOUNT_SID") { Rails.application.secrets.TWILIO_ACCOUNT_SID } 
      auth_token = ENV.fetch("TWILIO_AUTH_TOKEN") { Rails.application.secrets.TWILIO_AUTH_TOKEN }   

      test_account_sid = Rails.application.secrets.TEST_TWILIO_ACCOUNT_SID
      test_auth_token = Rails.application.secrets.TEST_TWILIO_AUTH_TOKEN

      # @client = Twilio::REST::Client.new account_sid, auth_token
    
      # formatted_phone_number = "+1" + phone_number
      # message = @client.messages.create(
      #   body: "Welcome #{message}. Your Wayvo verification code is: #{user.email_code}",
      #   to: formatted_phone_number,
      #   from: "+16474902706" 
      # )  

      # puts message.sid
      puts user.email_code 
      puts "???????????????????????????"
      render json: { is_success: true, access_token: user.access_token, new_user: new_user }, status: :ok
    end   
  end


  def verify_with_sms_code
    user = User.find_by(access_token: params[:access_token])
    if user.email_code == params[:email_code].to_i
      if user.phone_number && user.fullname && user.username 
        #login
        render json: {
            is_success: true,
            new_user: false,
            access_token: user.access_token, 
            phone_number: user.phone_number, 
            fullname: user.fullname, 
            username: user.username,
            # university_id: user.university_id,
            # university_name: user.university.university_name
          }, 
            status: :ok
      else
        #signup
         render json: {is_success: true, access_token: user.access_token, new_user: true}, status: :ok #university_id: user.university_id, university_name: user.university.university_name
      
        # check if this user has been invited before to create an invitation 
        text_invitations = TextInvitation.all.where(phone_number: user.phone_number, is_user: false)
        text_invitations.each do |inv|
          Invitation.create(user_id: inv.user_id, invitation_recipient_id: user.id)
          inv.is_user = true 
          inv.save 
        end
      end

    else
      render json: { is_success: false, error: "Incorrect code" }, status: :ok
    end
  end


  def get_contacts_from_db
    merged_contacts = @current_user.phone_contacts + @current_user.username_contacts
    render json: { is_success: true, merged_contacts: merged_contacts}, status: :ok
  end

  def save_phone_contacts
    @current_user.phone_contacts = params[:contacts]
    if @current_user.save 
      merged_contacts = @current_user.phone_contacts + @current_user.username_contacts
      render json: { is_success: true, merged_contacts: merged_contacts}, status: :ok
    else
      render json: { is_success: false}, status: :ok
    end
  end


  def save_username_contact 
    #recordID, givenName, familyName, phoneNumbers: [ {"label": "mobile", "number": "6475542523"} ], from_phone: false 
    user_to_add = User.find_by(username: params[:username]) # the username the current user is trying to add 
    can_add_for_current_user = true 
    can_add_current_user = true 

    ###### this is incorrect because it does not check if the username is in the contact list
    # check if the user already belongs to the user.username_contacts array 
    merged_contacts = @current_user.username_contacts + @current_user.phone_contacts
    merged_contacts.each do |obj|
      if obj["recordID"] == (user_to_add.id.to_s + user_to_add.phone_number.to_s)
        can_add_for_current_user = false 
      end 
    end

    if can_add_for_current_user
      new_obj = {
        recordID: (user_to_add.id.to_s + user_to_add.phone_number.to_s),
        givenName: user_to_add.first_name,
        familyName: user_to_add.last_name, 
        phoneNumbers: [ {label: "mobile", number: user_to_add.phone_number} ],
        from_username: true 
      }

      @current_user.username_contacts.push(new_obj)

      if @current_user.save 
        merged_contacts = @current_user.phone_contacts + @current_user.username_contacts
        render json: { is_success: true, merged_contacts: merged_contacts}, status: :ok
      end 

    else
      render json: { is_success: false, error_message: "#{user_to_add.first_name} is already a friend"}, status: :ok
    end


    #silently try to save for the user_to_add.username_contacts as well 
    other_merged_contacts = user_to_add.username_contacts + user_to_add.phone_contacts
    other_merged_contacts.each do |obj|
      if obj["recordID"] == (@current_user.id.to_s + @current_user.phone_number.to_s)
        can_add_current_user = false
      end
    end

    if can_add_current_user
      new_obj = {
        recordID: ( @current_user.id.to_s + @current_user.phone_number.to_s),
        givenName:  @current_user.first_name,
        familyName:  @current_user.last_name, 
        phoneNumbers: [ {label: "mobile", number:  @current_user.phone_number} ],
        from_username: true 
      }

      user_to_add.username_contacts.push(new_obj)
      user_to_add.save 
    end

  end


  def delete_contact 
    contactID = params[:contactID]
    if params[:from_username]
      @current_user.username_contacts = @current_user.username_contacts.reject { |contact| contact["recordID"] == contactID }
    else
      @current_user.phone_contacts = @current_user.phone_contacts.reject { |contact| contact["recordID"] == contactID }
    end

    if @current_user.save 
      merged_contacts = @current_user.username_contacts + @current_user.phone_contacts
      render json: { is_success: true, merged_contacts: merged_contacts}, status: :ok

    else
      render json: { is_success: false }, status: :ok
    end
    
  end


def save_time_zone
  @current_user.time_zone = params[:time_zone]
  @current_user.time_zone_offset = params[:time_zone_offset]
  if @current_user.save
    render json: { is_success: true}, status: :ok
  else
    render json: { is_success: false}, status: :ok
  end
end

def send_invite_to_catch_up
  name_and_number = params[:name_and_number].to_json
  SendNotificationToCatchUpJob.perform_now(@current_user, name_and_number)
  render json: { is_success: true}, status: :ok
end


end



























































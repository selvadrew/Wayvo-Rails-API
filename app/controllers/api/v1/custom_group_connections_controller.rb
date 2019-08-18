class Api::V1::CustomGroupConnectionsController < ApplicationController
  before_action :authenticate_with_token!

def create
    require 'fcm'
    fcm = FCM.new("AAAAAOXsHmg:APA91bFeO5xEEP3Zqkg1Ht3ocwzphQ9uEFGdUHHbRsGHAaVSqEXdJWAUo026ENDbFKJ6Sxy7UFRBYmm-ZH6NOkBGRbZvWhWtm8beW0lRtJivIdoExzfkiYk5QWj98kfTB9-sE4gD6oX-")
    
    custom_group_id = params[:custom_group_id]
    actual_group = CustomGroup.find_by(id: custom_group_id)
    @user = User.find_by(access_token: params[:access_token])

    #find friend user ids, connected with already from same group, and all group members excluding self
    #friends
    friends = Friendship.all.where(user_id: current_user.id).pluck(:friend_id)
    friends2 = Friendship.all.where(friend_id: current_user.id).pluck(:user_id)
    #all group members with current user removed 
    all_group_members = CustomGroupMember.all.where(custom_group_id: custom_group_id).pluck(:user_id) - [@user.id]
    #group connections
    group_connections_a = CustomGroupConnection.all.where(outgoing_user_id: @user.id).where.not(acceptor_user_id: nil).pluck(:acceptor_user_id)
    group_connections_b = CustomGroupConnection.all.where(acceptor_user_id: @user.id).pluck(:outgoing_user_id)
    group_connections = group_connections_a + group_connections_b

    minutes = 10 # minutes someone will be active in group - used to check if someone is active for user to say hello
    hours = 2 # hours someone has to wait to say hello to group again 
    filter_time = DateTime.now.utc - minutes.minutes
    filter_user_time = DateTime.now.utc - hours.hours 
    
    #check if anyone else from the program group is active 
    group_active_exists = CustomGroupConnection.all.where("created_at > ?", filter_time).where(custom_group_id: custom_group_id, acceptor_user_id: nil).pluck(:outgoing_user_id)
    prevent_spam = CustomGroupConnection.where("created_at > ?", filter_user_time).where(custom_group_id: custom_group_id, outgoing_user_id: @user.id ) 

    #removes friends, group connections, and self from active list so user can still say hello to group 
    filter_active = group_active_exists - friends - friends2 - group_connections - [@user.id]

    if friends.count < 1 
      render json: {error: "You need at least 1 friend from your school in your Friends list to use this feature. Invite a friend to Wayvo :)", is_success: false, get_more_friends: true }, status: :ok

    elsif filter_active.count > 0
      render json: {error: "You can't Say Hello when someone in the group is live, Say Hello Back instead.", group_is_live: true, is_success: false}, status: :ok
    
    elsif prevent_spam.count > 0
      render json: {error: "You can only Say Hello to the same group every #{hours} hours. Try again soon.", is_success: false, prevent_spam: true}, status: :ok
      
    else
      # find group members who accepted in the last 10 minutes to not send them another notification
      # and confuse them 
      was_connected = CustomGroupConnection.all.where("created_at > ?", filter_time).where(
      custom_group_id: custom_group_id).where.not(acceptor_user_id: nil).pluck(:acceptor_user_id)

      # add group members and connected members to remove duplicates(both instances)
      # to figure out who to send notifications to 
      # because the resulting array outputs group members that user hasnt connected to 
      group = group_connections + all_group_members
      members_to_meet = group.group_by{ |e| e }.select { |k, v| v.size == 1 }.map(&:first)
      notification_list = members_to_meet - friends - friends2 - was_connected
      notification_list_firebase = User.all.where(id: notification_list).pluck(:firebase_token)

      #create new object for outgoing group call 
      outgoing_custom_group_call = CustomGroupConnection.new(custom_group_id: custom_group_id, outgoing_user_id: @user.id)
      if outgoing_custom_group_call.save 
        render json: 
        { 
          is_success: true, 
          user: @user.fullname, 
          friends: friends, 
          friends2: friends2,
          all_group_members: all_group_members,
          group_connections: group_connections,
          members_to_meet: members_to_meet,
          notification_list: notification_list,
          group_active_exists: group_active_exists,
          seconds_left: minutes * 60,
          was_connected: was_connected
        }, 
        status: :ok

        #notification data 
        registration_ids = notification_list_firebase
        @notification = {
            title: "Make a new friend!",
            body: "Someone in #{actual_group.name} says hello",
            sound: "default"
          }
        options = {notification: @notification, priority: 'high', data: {outgoing: true}}
        response = fcm.send(registration_ids, options)

      else
        render json: { is_success: false }, status: :ok 
      end
    end#group_active_exists
  end#create

def said_hello_back_custom_group
	require 'fcm'
  fcm = FCM.new("AAAAAOXsHmg:APA91bFeO5xEEP3Zqkg1Ht3ocwzphQ9uEFGdUHHbRsGHAaVSqEXdJWAUo026ENDbFKJ6Sxy7UFRBYmm-ZH6NOkBGRbZvWhWtm8beW0lRtJivIdoExzfkiYk5QWj98kfTB9-sE4gD6oX-")

	connection_object = CustomGroupConnection.find_by(id: params[:outgoing_id])
	outgoing_user_firebase_token = User.find_by(id: connection_object.outgoing_user_id).firebase_token

	#notification data 
  registration_ids = [outgoing_user_firebase_token]
  @notification = {
      title: "Expect a call shortly",
      body: "Someone in #{connection_object.custom_group.name} said hello back",
      sound: "default"
    }
  options = {notification: @notification, priority: 'high', data: {expect_group_call: true}}

  #if connection obj's acceptor is nil, save user in it and send notification 
  #if not nil check if its current user 
	if connection_object.acceptor_user_id.nil?
		connection_object.acceptor_user_id = current_user.id
		if connection_object.save 
			render json: { is_success: true }, status: :ok
			response = fcm.send(registration_ids, options)
		end
	elsif connection_object.acceptor_user_id == current_user.id
		render json: { is_success: true }, status: :ok
	else
		render json: { is_success: false }, status: :ok
	end
end


end

 #  #moved this into group_connections_controller to handle both at the same time 
	# def check_active_custom_groups
 #    # checks if any custom groups are live on the live screen 
 #    if current_user.verified 
 #      friends = Friendship.all.where(user_id: current_user.id).pluck(:friend_id)
 #      friends2 = Friendship.all.where(friend_id: current_user.id).pluck(:user_id)

 #      # get all custom groups the user is part of 
 #      all_groups_user_is_in = CustomGroupMember.all.where(user_id: current_user.id, status: true, notifications: true, blocked: false).pluck(:custom_group_id)
      
 #      #get all custom group connections 
 #      all_custom_connections = []
 #      all_groups_user_is_in.each do |custom_group_id|
 #      	custom_group_connections_a = CustomGroupConnection.all.where(custom_group_id: custom_group_id, outgoing_user_id: current_user.id).where.not(acceptor_user_id: nil).pluck(:acceptor_user_id)
 #      	custom_group_connections_b = CustomGroupConnection.all.where(custom_group_id: custom_group_id, acceptor_user_id: current_user.id).pluck(:outgoing_user_id)
 #      	custom_group_connections = custom_group_connections_a + custom_group_connections_b
 #      	all_custom_connections << custom_group_connections if custom_group_connections.present?
 #      end

 #      # figure out all people user cant connect to = adding friends and all group connections 
 #      cant_connect_to = friends + friends2 + all_custom_connections.flatten + [current_user.id]

 #      # find all the groups that are active
 #      filter_time = DateTime.now.utc - 10.minutes
 #      custom_is_active = CustomGroupConnection.all.where("created_at > ?", filter_time).where(custom_group_id: all_groups_user_is_in).where.not(outgoing_user_id: cant_connect_to.uniq)

 #      live_custom_group_details = []
 #      custom_is_active.each do |active| 
 #      	@user = User.find_by(id: active.outgoing_user_id)
 #      	connected = active.acceptor_user_id == current_user.id # checks if current user is connected 
 #      	call_details = {
 #      		outgoing_id: active.id , 
 #      		group_name: CustomGroup.find_by(id: active.custom_group_id).name, 
 #      		phone_number: @user.phone_number, 
 #      		ios: @user.iOS, 
 #      		active: true, 
 #      		connected: connected
 #      	}
 #      	live_custom_group_details << call_details
 #      end

 #      # check if there are any live groups 
 #      if live_custom_group_details.present?
 #      	render json: { live_custom_groups: live_custom_group_details, is_success: true }, status: :ok  
 #     	else 
 #     		render json: { is_success: false }, status: :ok
 #     	end

 #    else 
 #       render json: { is_success: false }, status: :ok  
 #    end

 #  end

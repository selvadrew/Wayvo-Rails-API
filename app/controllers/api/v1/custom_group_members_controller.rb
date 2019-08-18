class Api::V1::CustomGroupMembersController < ApplicationController
  before_action :authenticate_with_token!

# this request gets all the details for the custom group screen 
# if admin get the members and requests 
# get all connections 
# get activity - last five connections 

  def get_all_custom_group_data
    custom_group = CustomGroup.find_by(id: params[:id])
    
    admin_data = {requested_members: false, accepted_members: false, blocked_members: false}
    is_admin = false
    connections_data = false 
    activity_data = false 

    only_admin_in_group = false 
    if CustomGroupMember.where(custom_group_id: params[:id], status: true).count == 1 
      only_admin_in_group = true
    end

    ############ ADMIN ############
    if custom_group.user_id == current_user.id
      #add accepted users and requested users separately
      requested_members = CustomGroupMember.joins(:user).where(custom_group_id: params[:id], status: false, blocked: false).order(created_at: :desc).pluck(:id, :fullname, :username).map {|id, fullname, username| {id: id, fullname: fullname, username: username, status: false, blocked: false} }
      accepted_members = CustomGroupMember.joins(:user).where(custom_group_id: params[:id], status: true, blocked: false).where.not(users: {id: current_user.id}).order("users.fullname").pluck(:id, :fullname, :username).map {|id, fullname, username| {id: id, fullname: fullname, username: username, status: true, blocked: false} }
      blocked_members = CustomGroupMember.joins(:user).where(custom_group_id: params[:id], status: false, blocked: true).order("users.fullname").pluck(:id, :fullname, :username).map {|id, fullname, username| {id: id, fullname: fullname, username: username, status: false, blocked: true} }

      admin_data = requested_members+accepted_members+blocked_members#{requested_members: requested_members, accepted_members: accepted_members, blocked_members: blocked_members}
      is_admin = true 
    end

    ############ CONNECTIONS ############
    group_connections_a = CustomGroupConnection.all.where(custom_group_id: params[:id], outgoing_user_id: current_user.id).where.not(acceptor_user_id: nil).pluck(:acceptor_user_id, :updated_at).map { |acceptor_user_id, updated_at| {connected_user: acceptor_user_id, updated_at: updated_at}}
    group_connections_b = CustomGroupConnection.all.where(custom_group_id: params[:id], acceptor_user_id: current_user.id).pluck(:outgoing_user_id, :updated_at).map { |outgoing_user_id, updated_at| {connected_user: outgoing_user_id, updated_at: updated_at}}
    group_connections = group_connections_a + group_connections_b

    if group_connections.count > 0 
      friends = Friendship.all.where(user_id: current_user.id).pluck(:friend_id)
      connections = group_connections.sort! { |x,y| y[:updated_at] <=> x[:updated_at] }
      connections_ids = connections.pluck(:connected_user)
      connected_users = User.all.where(id: connections_ids).pluck(:id, :fullname, :username).map { |id, fullname, username| {id: id, fullname: fullname, username: username, friends: false}}
      people_in_order = connected_users.sort_by {|p| connections_ids.index(p[:id]) }
      people_in_order.each do |user| 
        if friends.include? user[:id]
          user[:friends] = true 
        end
      end

      connections_data = people_in_order
    end

    ############ ACTIVITY ############
    recent_activity = CustomGroupConnection.where(custom_group_id: params[:id]).where.not(acceptor_user_id: nil).limit(5).order('id desc').pluck(:outgoing_user_id, :acceptor_user_id).map {|outgoing_user_id, acceptor_user_id| {outgoing_user: User.where(id: outgoing_user_id).pluck(:fullname), acceptor_user: User.where(id: acceptor_user_id).pluck(:fullname) }}
    if recent_activity.count > 0
      activity_data = recent_activity
    end

    render json: { 
      admin_data: admin_data, 
      connections_data: connections_data, 
      activity_data: activity_data, 
      is_admin: is_admin, 
      only_admin_in_group: only_admin_in_group, 
      is_success: true,
    }
    
  end

    # user enters username 
    # check if same school 

    # if exists check if already a member 
    # if member say already a member/ if waiting for approval show 
    # if not member show details - description, name, creator
    # join creates group member with false value 

    #user will enter unsername 
    #if it doesn't exist say it doesnt exist 
    #if not in current school say don't have access 
  def search_groups
    requestors_school = Program.joins(:program_group_members).where(program_group_members: {user_id: current_user.id} ).pluck(:university_id)
    group_info = false
    different_school = false
    
    CustomGroup.where(username: params[:username].downcase.strip).find_each do |group|
      creators_school = Program.joins(:program_group_members).where(program_group_members: {user_id: group.user_id} ).pluck(:university_id)
      if creators_school == requestors_school
        group_info = group
      else
        different_school = true
      end
    end

    if group_info
      admin = User.find_by(id: group_info.user_id)
      registered = CustomGroupMember.find_by(custom_group_id: group_info.id, user_id: current_user.id)
      if registered
        #already requested to join - status indicates if approved or not 
        render json: { is_success: true, requested: true, group_status: registered.status, admin: admin.fullname, name: group_info.name, description: group_info.description, group_id: group_info.id  }, status: :ok 
      else
        #group member object doesnt exist for user
        render json: { is_success: true, requested: false, admin: admin.fullname, name: group_info.name, description: group_info.description, group_id: group_info.id  }, status: :ok
      end

    else
      if different_school
        render json: { is_success: false, error: 1 }, status: :ok # don't have access to this group
      else
        render json: { is_success: false, error: 2 }, status: :ok # group doesnt exist 
      end
    end
  end


  def request_to_join
    require 'fcm'
    fcm = FCM.new("AAAAAOXsHmg:APA91bFeO5xEEP3Zqkg1Ht3ocwzphQ9uEFGdUHHbRsGHAaVSqEXdJWAUo026ENDbFKJ6Sxy7UFRBYmm-ZH6NOkBGRbZvWhWtm8beW0lRtJivIdoExzfkiYk5QWj98kfTB9-sE4gD6oX-")

    group_info = CustomGroup.find_by(id: params[:group_id])
    creators_school = Program.joins(:program_group_members).where(program_group_members: {user_id: group_info.user_id} ).pluck(:university_id)
    requestors_school = Program.joins(:program_group_members).where(program_group_members: {user_id: current_user.id} ).pluck(:university_id)
    registered = CustomGroupMember.find_by(custom_group_id: group_info.id, user_id: current_user.id)

    if creators_school == requestors_school && !registered
      @request_approval = group_info.custom_group_member.build(user_id: current_user.id, status: false, notifications: true)
      if @request_approval.save 
        # notif
        firebase_token = User.where(id: group_info.user_id).pluck(:firebase_token)
        @notification = {
          title: "New member request for #{group_info.name}",
          body: "Accept #{current_user.fullname} to give them access to your group",
          sound: "default"
        }
        registration_ids = firebase_token
        options = {notification: @notification, priority: 'high', data: {group: true}}
        response = fcm.send(registration_ids, options)

        render json: { is_success: true }, status: :ok #wait for approval now 
      else
        render json: { is_success: false }, status: :ok #something went wrong
      end
    else
      render json: { is_success: false}, status: :ok #different school
    end
  end

  def add_to_group 
    require 'fcm'
    fcm = FCM.new("AAAAAOXsHmg:APA91bFeO5xEEP3Zqkg1Ht3ocwzphQ9uEFGdUHHbRsGHAaVSqEXdJWAUo026ENDbFKJ6Sxy7UFRBYmm-ZH6NOkBGRbZvWhWtm8beW0lRtJivIdoExzfkiYk5QWj98kfTB9-sE4gD6oX-")

    member_info = CustomGroupMember.find_by(id: params[:id])
    #send notification if first time approved 
    if member_info.blocked 
      send_notif = false 
    else
      send_notif = true
    end

    member_info.status = true 
    member_info.blocked = false 
    if member_info.save 
      render json: { is_success: true, group_id: member_info.custom_group_id }, status: :ok 
      
      if send_notif 
        @notification = {
          title: "You've been added to #{member_info.custom_group.name}",
          body: "Start a plan with all the members soon! Live it up!",
          sound: "default"
        }
        firebase_token = User.where(id: member_info.user_id).pluck(:firebase_token)

        registration_ids = firebase_token
        options = {notification: @notification, priority: 'high', data: {group: true}}
        response = fcm.send(registration_ids, options)
      end
    
    else
      render json: { is_success: false}, status: :ok 
    end
  end

  def deny_to_group
    member_info = CustomGroupMember.find_by(id: params[:id])
    member_info.status = false
    member_info.blocked = true 

    if member_info.save 
      render json: { is_success: true, group_id: member_info.custom_group_id }, status: :ok 
    else
      render json: { is_success: false}, status: :ok 
    end
    
  end





end 












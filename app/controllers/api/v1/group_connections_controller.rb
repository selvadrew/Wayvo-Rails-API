class Api::V1::GroupConnectionsController < ApplicationController
  before_action :authenticate_with_token!
# https://stackoverflow.com/questions/8921999/ruby-how-to-find-and-return-a-duplicate-value-in-array
  def create
    require 'fcm'
    fcm = FCM.new("AAAAAOXsHmg:APA91bFeO5xEEP3Zqkg1Ht3ocwzphQ9uEFGdUHHbRsGHAaVSqEXdJWAUo026ENDbFKJ6Sxy7UFRBYmm-ZH6NOkBGRbZvWhWtm8beW0lRtJivIdoExzfkiYk5QWj98kfTB9-sE4gD6oX-")
    
    program_id = params[:program_id]
    program = Program.find_by(id: program_id)
    @user = User.find_by(access_token: params[:access_token])

    #find friend user ids, connected with already from same group, and all group members excluding self
    #friends
    friends = Friendship.all.where(user_id: current_user.id).pluck(:friend_id)
    friends2 = Friendship.all.where(friend_id: current_user.id).pluck(:user_id)
    #all group members with current user removed 
    all_group_members = ProgramGroupMember.all.where(program_id: program_id).pluck(:user_id) - [@user.id]
    #group connections
    group_connections_a = GroupConnection.all.where(outgoing_user_id: @user.id).where.not(acceptor_user_id: nil).pluck(:acceptor_user_id)
    group_connections_b = GroupConnection.all.where(acceptor_user_id: @user.id).pluck(:outgoing_user_id)
    group_connections = group_connections_a + group_connections_b

    minutes = 10 # minutes someone will be active in group - used to check if someone is active for user to say hello
    hours = 0 # hours someone has to wait to say hello to group again 
    filter_time = DateTime.now.utc - minutes.minutes
    filter_user_time = DateTime.now.utc - hours.hours 
    
    #check if anyone else from the program group is active 
    group_active_exists = GroupConnection.all.where("created_at > ?", filter_time).where(program_id: program_id, acceptor_user_id: nil).pluck(:outgoing_user_id)
    prevent_spam = GroupConnection.where("created_at > ?", filter_user_time).where(program_id: program_id, outgoing_user_id: @user.id ) 

    #removes friends, group connections, and self from active list so user can still say hello to group 
    filter_active = group_active_exists - friends - friends2 - group_connections - [@user.id]

    if friends.count < 3 
      render json: {error: "You need at least 3 friends from your school in your Friends list to use this feature. Invite your friends to Wayvo :)", is_success: false, get_more_friends: true }, status: :ok

    elsif filter_active.count > 0
      render json: {error: "You can't Say Hello when someone in the group is live, Say Hello Back instead.", group_is_live: true, is_success: false}, status: :ok
    
    elsif prevent_spam.count > 0
      render json: {error: "You can only Say Hello to the same group every #{hours} hours. Try again soon.", is_success: false, prevent_spam: true}, status: :ok
      
    else
      # find group members who accepted in the last 10 minutes to not send them another notification
      # and confuse them 
      was_connected = GroupConnection.all.where("created_at > ?", filter_time).where(
      program_id: program_id).where.not(acceptor_user_id: nil).pluck(:acceptor_user_id)


      # add group members and connected members to remove duplicates(both instances)
      # to figure out who to send notifications to 
      # because the resulting array outputs group members that user hasnt connected to 
      group = group_connections + all_group_members
      members_to_meet = group.group_by{ |e| e }.select { |k, v| v.size == 1 }.map(&:first)
      notification_list = members_to_meet - friends - friends2 - was_connected
      notification_list_firebase = User.all.where(id: notification_list).pluck(:firebase_token)

      #create new object for outgoing group call 
      outgoing_group_call = GroupConnection.new(program_id: program_id, outgoing_user_id: @user.id)
      if outgoing_group_call.save 
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
            body: "Someone in #{program.program_name} says hello.",
            sound: "default"
          }
        options = {notification: @notification, priority: 'high', data: {outgoing: true}}
        response = fcm.send(registration_ids, options)

      else
        render json: { is_success: false }, status: :ok 
      end

    end#group_active_exists

  end#create


    # check if the user is live for groups - said hello to groups 
    # get users last outgoing for groups 
    # check if within 10 minutes and acceptor is null 
    # output will be boolean and seconds_left if boolean true 
  def said_hello_groups
    #checks if user said hello to groups recently when app is killed and restarted 

    #@user = User.find_by(access_token: params[:access_token])

    minutes = 10 # minutes someone will be active in group 
    countdown_timer = minutes * 60 
    filter_time = DateTime.now.utc - minutes.minutes

    last_said_hello = GroupConnection.where("created_at > ?", filter_time).where(outgoing_user_id: current_user.id, acceptor_user_id: nil).last

    if last_said_hello
      render json: { last_said_hello: last_said_hello.created_at, countdown_timer: countdown_timer, is_success: true }, status: :ok 
    else
      render json: { is_success: false }, status: :ok 
    end

    
  end



  def check_active_groups
    # checks if any groups are live on the live screen 
    if current_user.verified 
      # if group was active within 20 minutes, show it 

      #find friend user ids, connected with already from same group, and all group members excluding self
      #friends
      friends = Friendship.all.where(user_id: current_user.id).pluck(:friend_id)
      friends2 = Friendship.all.where(friend_id: current_user.id).pluck(:user_id)
      #all group members with current user removed 
      #group connections
      group_connections_a = GroupConnection.all.where(outgoing_user_id: current_user.id).where.not(acceptor_user_id: nil).pluck(:acceptor_user_id)
      group_connections_b = GroupConnection.all.where(acceptor_user_id: current_user.id).pluck(:outgoing_user_id)
      group_connections = group_connections_a + group_connections_b

      filter_is_active = friends + friends2 + group_connections + [current_user.id]

      # was group active within 20 minutes 
      filter_time = DateTime.now.utc - 10.minutes
      program_id = ProgramGroupMember.find_by(user_id: current_user.id).program_id
      program_name = Program.find_by(id: program_id).program_name
      is_active = GroupConnection.all.where("created_at > ?", filter_time).where(program_id: program_id).where.not(outgoing_user_id: filter_is_active)
      program_details = { program_name: program_name, program_id: program_id }

      # was connected within last 10 minutes - still show the group 
      already_connected = GroupConnection.where("created_at > ?", filter_time).where(program_id: program_id, acceptor_user_id: current_user.id).first

      if is_active.count > 0 || already_connected
        render json: { program_details: program_details, is_success: true }, status: :ok  

      else
        render json: { is_success: false }, status: :ok  
      end

    else 
       render json: { is_success: false }, status: :ok  
    end

  end


  def said_hello_back_groups
    #is run when user says hello back to groups 


    # when user says hello back first check if they've been connected with anyone in last 10 minutes
    # if they were, show the connected profile 
    # if not, see if any users are still live and connect them with first user that went live 
    # get all connected people within 20 minutes 
    # if not connected with anyone show all active people 
    # if connected with someone within 20 minutes, show 
    require 'fcm'
    fcm = FCM.new("AAAAAOXsHmg:APA91bFeO5xEEP3Zqkg1Ht3ocwzphQ9uEFGdUHHbRsGHAaVSqEXdJWAUo026ENDbFKJ6Sxy7UFRBYmm-ZH6NOkBGRbZvWhWtm8beW0lRtJivIdoExzfkiYk5QWj98kfTB9-sE4gD6oX-")

    program_id = params[:program_id]
    program = Program.find_by(id: program_id)

    filter_time = DateTime.now.utc - 10.minutes
    was_connected = GroupConnection.where("created_at > ?", filter_time).where(
      program_id: program_id, acceptor_user_id: current_user.id 
      ).last 

    still_live = GroupConnection.all.where("created_at > ?", filter_time).where(
      program_id: program_id, acceptor_user_id: nil).pluck(:outgoing_user_id)
    #still_live - friends1,2 - already connected members 

    if was_connected 
      connected_user = User.find_by(id: was_connected.outgoing_user_id)
      connected_user_data = {phone_number: connected_user.phone_number, iOS: connected_user.iOS}
      render json: { call_details: connected_user_data, connected: true, was_connected: true, is_success: true }, status: :ok  
    else

      #find friend user ids, connected with already from same group, and all group members excluding self
      #friends
      friends = Friendship.all.where(user_id: current_user.id).pluck(:friend_id)
      friends2 = Friendship.all.where(friend_id: current_user.id).pluck(:user_id)
      #all group members with current user removed 
      all_group_members = ProgramGroupMember.all.where(program_id: program_id).pluck(:user_id) - [current_user.id]
      #group connections
      group_connections_a = GroupConnection.all.where(outgoing_user_id: current_user.id).where.not(acceptor_user_id: nil).pluck(:acceptor_user_id)
      group_connections_b = GroupConnection.all.where(acceptor_user_id: current_user.id).pluck(:outgoing_user_id)
      group_connections = group_connections_a + group_connections_b

      group = group_connections + all_group_members
      members_to_meet = group.group_by{ |e| e }.select { |k, v| v.size == 1 }.map(&:first)
      can_meet = members_to_meet - friends - friends2
      can_connect = can_meet + still_live
      connect = can_connect.group_by{ |e| e }.select { |k, v| v.size > 1 }.map(&:first)

      if connect.length > 0
        connected_to = User.find_by(id: connect.first)
        call_details = {phone_number: connected_to.phone_number, iOS: connected_to.iOS}

        live_object = GroupConnection.where("created_at > ?", filter_time).where(
          program_id: program_id, acceptor_user_id: nil, outgoing_user_id: connected_to.id).first

        live_object.acceptor_user_id = current_user.id 

        #notification data 
        registration_ids = [connected_to.firebase_token]
        @notification = {
            title: "Expect a call shortly.",
            body: "Someone in #{program.program_name} said hello back.",
            sound: "default"
          }
        options = {notification: @notification, priority: 'high', data: {expect_group_call: true}}
        

        if live_object.save 
          render json: {call_details: call_details, is_success: true, new_connection: true, connected: true}, status: :ok 
          response = fcm.send(registration_ids, options)
        else
          render json: { is_success: false, connected: false }, status: :ok
        end 
      else
        render json: { is_success: false, connected: false }, status: :ok
      end
    end


  end #said_hello_back_groups



  def connected_users 
    # get all connected users and ask if they want to add them as a friend 
    # array should have connected fullname, username, and friend status, ordered by most recent 

    program_id = params[:program_id]
    friends = Friendship.all.where(user_id: current_user.id).pluck(:friend_id)

    group_connections_a = GroupConnection.all.where(outgoing_user_id: current_user.id).where.not(acceptor_user_id: nil).pluck(:acceptor_user_id, :updated_at).map { |acceptor_user_id, updated_at| {connected_user: acceptor_user_id, updated_at: updated_at}}
    group_connections_b = GroupConnection.all.where(acceptor_user_id: current_user.id).pluck(:outgoing_user_id, :updated_at).map { |outgoing_user_id, updated_at| {connected_user: outgoing_user_id, updated_at: updated_at}}
    group_connections = group_connections_a + group_connections_b
    connections = group_connections.sort! { |x,y| y[:updated_at] <=> x[:updated_at] }
    connections_ids = connections.pluck(:connected_user)
    connected_users = User.all.where(id: connections_ids).pluck(:id, :fullname, :username).map { |id, fullname, username| {id: id, fullname: fullname, username: username, friends: false}}
    people_in_order = connected_users.sort_by {|p| connections_ids.index(p[:id]) }
    people_in_order.each do |user| 
      if friends.include? user[:id]
        user[:friends] = true 
      end
    end


    if group_connections
      render json: { is_success: true, group_connections: people_in_order}, status: :ok
    else 
      render json: { is_success: false }, status: :ok
    end 


  end









end 






















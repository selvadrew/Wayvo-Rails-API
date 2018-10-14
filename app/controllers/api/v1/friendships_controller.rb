class Api::V1::FriendshipsController < ApplicationController
  before_action :authenticate_with_token!

  def create

    require 'fcm'
    fcm = FCM.new("AAAAAOXsHmg:APA91bFeO5xEEP3Zqkg1Ht3ocwzphQ9uEFGdUHHbRsGHAaVSqEXdJWAUo026ENDbFKJ6Sxy7UFRBYmm-ZH6NOkBGRbZvWhWtm8beW0lRtJivIdoExzfkiYk5QWj98kfTB9-sE4gD6oX-")
    firebase_token = []

    username = params[:username]
    sanitized_username = username.downcase
    add_friend = User.where(username: sanitized_username).first
    

    if add_friend
      if add_friend.id == current_user.id 
        render json: { error: "You cannot add yourself", is_success: false}, status: 404
      else 

        friend_name = add_friend.fullname

        # Checks if friendship already exists 
        check_friendship = Friendship.where(
          "user_id = ? AND friend_id = ?",
          current_user.id, add_friend.id
          ).count
        
        # Checks if inverse friendship already exists 
        check_inverse_friendship = Friendship.where(
          "user_id = ? AND friend_id = ?",
          add_friend.id, current_user.id
          ).count

        # Declare inverse friendship if it exists 
        if check_inverse_friendship == 1 
          @inverse_friendship = Friendship.where(
          "user_id = ? AND friend_id = ?",
          add_friend.id, current_user.id
          ).first 
        end

        @notification = {
          title: "New Contact Request",
          body: "#{current_user.fullname} added you to their contact list",
          sound: "default"
        }
        firebase_token << add_friend.firebase_token

        registration_ids = firebase_token
        options = {notification: @notification, priority: 'high', data: {friend: true}}

        ### actual conditions 
        if check_friendship == 0
          @friendship = current_user.friendships.build(:friend_id => add_friend.id)
          if check_inverse_friendship == 1 
            @friendship.status = "FRIENDSHIP"
            @inverse_friendship.status = "FRIENDSHIP"
            @inverse_friendship.save 
          else
            @friendship.status = "WAITING"
          end
           
          if @friendship.save
            render json: {is_success: true, id: add_friend.id, fullname: add_friend.fullname, username: add_friend.username, phone_number: add_friend.phone_number}, status: :ok
            if @friendship.status == "WAITING"
              response = fcm.send(registration_ids, options)
            end

          else
            render json: { error: "Error while saving friend", is_success: false}, status: 404
          end

        else
          render json: { error: "#{friend_name} is already a contact", is_success: false}, status: 404
        end
      end

    else 
      render json: { error: "Username does not exist", friend: add_friend, is_success: false}, status: 404
    end 


  end

  def destroy

    @friendship = Friendship.where(
      "user_id = ? AND friend_id = ?",
      current_user.id, params[:friend_id]
    ).first

    # Checks if inverse friendship already exists 
    check_inverse_friendship = Friendship.where(
      "user_id = ? AND friend_id = ?",
      params[:friend_id], current_user.id
      ).count

    # Declare inverse friendship if it exists 
    if check_inverse_friendship == 1 
      @inverse_friendship = Friendship.where(
      "user_id = ? AND friend_id = ?",
      params[:friend_id], current_user.id
      ).first 
    end

    if @friendship 
      if @friendship.destroy
        if check_inverse_friendship == 1 
          @inverse_friendship.status = "DELETED FRIENDSHIP"
          @inverse_friendship.save
        end
        render json: {is_success: true}, status: :ok
      else
        #dont think this is the best way to handle this error
        render json: {error: "Can't Delete", is_success: false}, status: 404
      end
    else 
      render json: {error: "Friendship does not exist", is_success: false}, status: 404
    end


  end



  def show_friends
    # find all objects in Friendships with my user_id
    # use all friend_id's to find the actual users information

    @related_friendships = Friendship.all.where(user_id: current_user.id)

    if @related_friendships.empty?
      render json: { is_success: false}, status: :ok
    else

      @friend_ids = []
      @related_friendships.each do |friendships|
        ting = friendships.friend_id
        @friend_ids << ting
        end 

      @friends = []
      @friend_ids.each do |friends| 
        @user = User.find_by(id: friends)
        @friends_list = { id: @user.id, fullname: @user.fullname, username: @user.username, phone_number: @user.phone_number }
        insert = @friends_list
        @friends << insert 
      end

      @friends.sort_by! { |x| x[:fullname].downcase }

      render json: {friends: @friends, is_success: true}, status: :ok

    end
  end


  def friend_requests 

    requested_friendships = User.friend_requests(current_user)

    if requested_friendships.empty?
      render json: { is_success: false}, status: :ok
    else

      requested_friendships.sort_by! { |x| x[:created_at] }.reverse!

      render json: {friend_requests: requested_friendships, is_success: true}, status: :ok

    end

  end


  def rejected

    @friendship = Friendship.where(
      "user_id = ? AND friend_id = ?",
      params[:user_id], current_user.id
    ).first

    if @friendship.status == "WAITING"
      @friendship.status = "REJECTED"
      if @friendship.save 
        render json: {is_success: true}, status: :ok
      else
        render json: { is_success: false}, status: :ok
      end
    else
      render json: { is_success: false}, status: 404
    end
    
  end


      




end
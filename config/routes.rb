Rails.application.routes.draw do
  mount ActionCable.server => '/cable'

  namespace :api, defaults: {format: :json} do
    namespace :v1 do
      post '/logout' => 'users#logout'
      post '/facebook' => 'users#facebook'
      post '/email_signup' => 'users#email_signup'
      post '/email_login' => 'users#email_login'
      post '/verify_with_email_code' => 'users#verify_with_email_code'
      post 'firebase_token' => 'users#store_firebase_token'
      post 'fullname' => 'users#save_fullname'
      post '/username' => 'users#check_username'
      post '/phonenumber' => 'users#add_phone_number'
      post 'send_email_code' => 'users#send_email_code'
      post '/friendship' => 'friendships#create'
      post '/friends' => 'friendships#show_friends'
      post '/friend_requests' => 'friendships#friend_requests'
      delete '/friendships' => 'friendships#destroy'
      post 'rejected' => 'friendships#rejected'
      post 'check_active' => 'outgoings#check_active'
      post 'last_connected' => 'outgoings#last_connected'
      post 'get_phone_number' => 'users#get_phone_number'
      post '/feedback' => 'feedbacks#create'
      post '/receive_notifications' => 'friendships#receive_notifications'
      post '/send_notifications' => 'friendships#send_notifications'
      post 'tester' => 'outgoings#tester'
      post 'universities' => 'universities#get_university'
      post 'programs' => 'universities#get_program'
      post 'request_to_join_program' => 'program_group_members#request_to_join_program'
      post 'get_program_group' => 'program_group_members#get_program_group'
      post 'said_hello_groups' => 'group_connections#said_hello_groups'
      post 'check_active_groups' => 'group_connections#check_active_groups'
      post 'said_hello_back_groups' => 'group_connections#said_hello_back_groups'
      post 'connected_users' => 'group_connections#connected_users'
      post 'create_group' => 'custom_groups#create'
      post 'get_custom_groups' => 'custom_group_members#get_custom_groups'
      post 'search_groups' => 'custom_group_members#search_groups'
      post 'request_to_join' => 'custom_group_members#request_to_join'
      post 'get_all_custom_group_data' => 'custom_group_members#get_all_custom_group_data'
      post 'add_to_group' => 'custom_group_members#add_to_group'
      post 'deny_to_group' => 'custom_group_members#deny_to_group'
      post 'check_active_custom_groups' => 'custom_group_connections#check_active_custom_groups'
      post 'said_hello_back_custom_group' => 'custom_group_connections#said_hello_back_custom_group'
      post 'get_live_plans' => 'plans#get_live_plans'
      post 'join_plan' => 'plans#join_plan'
      post 'get_messages' => 'plans#get_messages'
      post 'get_uni_requests' => 'users#get_uni_requests'
      post 'uni_request_update' => 'users#uni_request_update'
      post 'send_sms_code' => 'users#send_sms_code'
      post 'verify_with_sms_code' => 'users#verify_with_sms_code'
      post 'save_phone_contacts' => 'users#save_phone_contacts'
      post 'send_invite_to_catch_up' => 'users#send_invite_to_catch_up'
      post '/incoming_sms' => 'stops#incoming_sms'
      post 'save_time_zone' => 'users#save_time_zone'
      post 'get_calendar' => 'calendars#get_calendar'
      post 'set_calendar' => 'calendars#set_calendar'
      post 'all_user_invitation_data' => 'invitations#all_user_invitation_data'
      post 'show_friends_calendar' => 'calendars#show_friends_calendar'
      post 'book_friends_calendar' => 'calendars#book_friends_calendar'
      post 'get_contacts_from_db' => 'users#get_contacts_from_db'
      post 'save_username_contact' => 'users#save_username_contact'
      post 'delete_contact' => 'users#delete_contact'
      post 'log_active_user' => 'users#log_active_user'
      post 'set_relationship' => 'users#set_relationship'
      post 'time_to_catch_up' => 'invitations#time_to_catch_up'


      resources :friendships
      resources :conversations
      resources :outgoings
      resources :acceptors
      resources :feedbacks
      resources :group_connections
      resources :custom_group_connections
      resources :plans
      resources :plan_messages
      resources :stops
    end


  end




end

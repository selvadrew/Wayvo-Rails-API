Rails.application.routes.draw do

  namespace :api, defaults: {format: :json} do
    
    namespace :v1 do
      post '/logout' => 'users#logout'
      post '/facebook' => 'users#facebook'
      post '/email_signup' => 'users#email_signup'
      post '/email_login' => 'users#email_login'
      post 'firebase_token' => 'users#store_firebase_token'
      post 'fullname' => 'users#save_fullname'
      post '/username' => 'users#check_username'
      post '/phonenumber' => 'users#add_phone_number'
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



      resources :friendships
      resources :conversations
      resources :outgoings
      resources :acceptors
      resources :feedbacks
      resources :group_connections
    end


  end




end

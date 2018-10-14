Rails.application.routes.draw do

  namespace :api, defaults: {format: :json} do
    
    namespace :v1 do
      post '/logout' => 'users#logout'
      post '/facebook' => 'users#facebook'
      post 'firebase_token' => 'users#store_firebase_token'
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


      resources :friendships
      resources :conversations
      resources :outgoings
      resources :acceptors
      resources :feedbacks
    end


  end




end

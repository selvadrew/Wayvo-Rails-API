namespace :notifications do

  desc "send invitation - runs every 10 minutes"
  # iterate over all calendars and see what was updated in the last 20 minutes - for each user do the following 
  # check if there are any availabilites/ count them - continue if true 
  # check how many invitations were sent today in senders time zone - continue if less than 3  
  # check who it's time to catch up with
  # SendNotificationToCatchUpJob if there is anyone to catch up with - preference given to smaller relationship_days contacts 
  # if theres no one to catch up with, remind user to add relationships - save the date this is sent in db so its only sent once a day 
  # if first invitation send notification 

  task send_invitation: :environment do


  	
  	# SendNotificationToCatchUpJob.perform_now(User.find_by_id(163), [ {fullname:"Andew S", phoneNumber:"(647) 554-2523"} ] ) 
  	# puts "worked"
  end

  # rake notifications:reminder_fifteen_minutes
  task reminder_ten_minutes: :environment do 
    require 'fcm'
    fcm = FCM.new("AAAAAOXsHmg:APA91bFeO5xEEP3Zqkg1Ht3ocwzphQ9uEFGdUHHbRsGHAaVSqEXdJWAUo026ENDbFKJ6Sxy7UFRBYmm-ZH6NOkBGRbZvWhWtm8beW0lRtJivIdoExzfkiYk5QWj98kfTB9-sE4gD6oX-")

    upcoming_calls = Invitation.all.where("scheduled_call > ?", Time.now.utc).where("scheduled_call < ?", Time.now.utc + 15.minutes)

    upcoming_calls.each do |upcoming|
      first_user = User.find_by_id(upcoming.user_id)
      second_user = User.find_by_id(upcoming.invitation_recipient_id)

      first_registration_id = []
      second_registration_id = []
      first_registration_id << first_user.firebase_token 
      second_registration_id << second_user.firebase_token

      @first_notification = {
        title: "Reminder", 
        body: "Call with #{second_user.first_name} in 10 minutes 🙌",
        sound: "default"
      }

      @second_notification = {
        title: "Reminder:",
        body: "Call with #{first_user.first_name} in 10 minutes 🙌",
        sound: "default"
      }

      first_options = { notification: @first_notification, priority: 'high', data: { upcoming: true } } 
      first_response = fcm.send(first_registration_id, first_options)

      second_options = { notification: @second_notification, priority: 'high', data: { upcoming: true } } 
      second_response = fcm.send(second_registration_id, second_options)
    end

  end

end
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

end
namespace :manual_groups do

	#iterate through each uni
	#create user for all unis 
	#create program_group_member 
	#create custom_group 

  desc "create users"
  task create_uni_users: :environment do
  	unis = University.all  
  	unis.each do |uni|
  		uni_string = uni.id.to_s + "uni" 
  		User.create!(
  			fullname: uni.university_name, 
  			username: uni_string, 
  			password: "$secret123", 
  			phone_number: "6475542523", 
  			email: "#{uni_string}@gmail.com", 
  			iOS: true, 
  			verified: true, 
  			submitted: true, 
  			access_token: "universitymain",
  			enrollment_date: 2019
  		)
  	end
  end

  desc "fix access_token"
  task fix_access_token: :environment do
  	users = User.all.where(access_token: "universitymain")
  	users.each do |user|
  		user.access_token =  "universitymain" + user.id.to_s
  		user.save!
  	end
  end

  desc "create_program_groups"
  task create_program_groups: :environment do
  	unis = University.all  
  	unis.each do |uni|
  		uni_string = uni.id.to_s + "uni" 
  		user = User.find_by(username: uni_string)
  		ProgramGroupMember.create!(
  			program_id: uni.programs.first.id,
  			user_id: user.id,
  			notifications: true 
  		)
  	end
  end

  desc "create first year group"
  task create_custom_groups_1: :environment do
  	unis = University.all
  	unis.each do |uni|
  		uni_string = uni.id.to_s + "uni" 
  		user = User.find_by(username: uni_string)
  		custom_group = CustomGroup.new(
  			name: "All First Years",
  			user_id: user.id,
  			username: uni_string + "1", 
  			description: "Official university wide group"
  		)
  		custom_group.custom_group_member.build(user_id: user.id, status: true, blocked: false, notifications:true )
  		custom_group.save! 
  	end
  end

  desc "create second year group"
  task create_custom_groups_2: :environment do
  	unis = University.all
  	unis.each do |uni|
  		uni_string = uni.id.to_s + "uni" 
  		user = User.find_by(username: uni_string)
  		custom_group = CustomGroup.new(
  			name: "All Second Years",
  			user_id: user.id,
  			username: uni_string + "2", 
  			description: "Official university wide group"
  		)
  		custom_group.custom_group_member.build(user_id: user.id, status: true, blocked: false, notifications:true)
  		custom_group.save!
  	end
  end

  desc "create third year group"
  task create_custom_groups_3: :environment do
  	unis = University.all
  	unis.each do |uni|
  		uni_string = uni.id.to_s + "uni" 
  		user = User.find_by(username: uni_string)
  		custom_group = CustomGroup.new(
  			name: "All Third Years",
  			user_id: user.id,
  			username: uni_string + "3", 
  			description: "Official university wide group"
  		)
  		custom_group.custom_group_member.build(user_id: user.id, status: true, blocked: false, notifications:true)
  		custom_group.save!
  	end
  end

  desc "create fourth year group"
  task create_custom_groups_4: :environment do
  	unis = University.all
  	unis.each do |uni|
  		uni_string = uni.id.to_s + "uni" 
  		user = User.find_by(username: uni_string)
  		custom_group = CustomGroup.new(
  			name: "All Fourth Years",
  			user_id: user.id,
  			username: uni_string + "4", 
  			description: "Official university wide group"
  		)
  		custom_group.custom_group_member.build(user_id: user.id, status: true, blocked: false, notifications:true)
  		custom_group.save!
  	end
  end


end

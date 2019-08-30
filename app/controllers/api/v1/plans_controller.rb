class Api::V1::PlansController < ApplicationController
	before_action :authenticate_with_token!

	def create
		require 'fcm'
		fcm = FCM.new("AAAAAOXsHmg:APA91bFeO5xEEP3Zqkg1Ht3ocwzphQ9uEFGdUHHbRsGHAaVSqEXdJWAUo026ENDbFKJ6Sxy7UFRBYmm-ZH6NOkBGRbZvWhWtm8beW0lRtJivIdoExzfkiYk5QWj98kfTB9-sE4gD6oX-")
		activities = ["grab food", "hang out", "group study", "party"]
		#set which group type is starting the plan - program or custom_group 
		if params[:group_type] == 0 
			group = Program.find_by(id: params[:group_id])
			firebase_tokens = ProgramGroupMember.joins(:user).where(program_id: params[:group_id]).where.not(user_id: current_user.id).pluck(:firebase_token)
			group_name = group.program_name
		else
			group = CustomGroup.find_by(id: params[:group_id])
			firebase_tokens = CustomGroupMember.joins(:user).where(custom_group_id: params[:group_id], status: true, blocked: false, notifications: true).where.not(user_id: current_user.id).pluck(:firebase_token)
			group_name = group.name
		end

		#check if plan exists within 2 hours 
		allow_plan = true 
		recent_plan = Plan.where("created_at > ?", 2.hours.ago).where(group: group).first
		if recent_plan 
			allow_plan = false 
		end

		if allow_plan
			plan = Plan.new(
				group: group, 
				user_id: current_user.id, 
				activity: params[:activity], 
				time: params[:time], 
				exploding_offer: params[:exploding_offer]  
			)
			if plan.save
				render json: { is_success: true }, status: :ok
				#notification data 
				exploding_offer = ["5 minutes", "10 minutes", "30 minutes", "1 hour", "4 hours"]
        registration_ids = firebase_tokens
        @notification = {
            title: "#{current_user.fullname} started a plan in #{group_name}",
            # body: "You have #{exploding_offer[params[:exploding_offer]]} to respond before it disappears",
            body: "The invite expires in #{exploding_offer[params[:exploding_offer]]}, don't miss out.",
            sound: "default"
          }

        options = {notification: @notification, priority: 'high', data: {outgoing: true}}
        response = fcm.send(registration_ids, options)

        plan_message = PlanMessage.new(
        	plan_id: plan.id,
        	user_id: current_user.id, 
        	content: "This chat includes all the group members who will be attending this plan. Once a member presses 'I'M IN', they automatically get added to this group chat. Use this chat to finalize the location and other details of the plan.",
        	system_message: true
      	)	

      	if plan_message.save
	        plan_member = PlanMember.create(
	        	plan_id: plan.id,
	        	user_id: current_user.id
	        )
      	end

        # plan_message = PlanMessage.create(
        # 	plan_id: plan.id,
        # 	user_id: current_user.id, 
        # 	content: "I'm in!"
        # 	)

			else 
				render json: { is_success: false, error: "Sorry, something went wrong." }, status: :ok
			end
		else
			render json: { is_success: false, error1: "Try again in a few minutes", error2: "New plans can only be created every two hours for this group"}, status: :ok
		end
	end

	def get_live_plans
		
		# if is_happening, show it 
		# if not_happening yet check if now < created_at + exploding_offer 
			# if true show plan and calculate how many minutes left 

		# for all live plans check if plan_member exists  
		# if going load messages too 
		
		if current_user.verified 
			all_groups_user_is_in = CustomGroupMember.all.where(user_id: current_user.id, status: true, notifications: true, blocked: false).pluck(:custom_group_id)
			program_id = ProgramGroupMember.find_by(user_id: current_user.id).program_id

			# get all groups(custom + program) that belong to the user in the last 24 hours 
			filter_time = DateTime.now.utc - 24.hours
			custom_plans = Plan.all.where("created_at > ?", filter_time).where(group_type:"CustomGroup", group_id: all_groups_user_is_in)
			program_plans = Plan.all.where("created_at > ?", filter_time).where(group_type:"Program", group_id: program_id)
			all_plans_last_24h = custom_plans + program_plans

			plans_to_show = []
			all_plans_last_24h.each do |plan|
				if plan.group_type == "Program"
					group_name = Program.find_by(id: plan.group_id).program_name
				else
					group_name = CustomGroup.find_by(id: plan.group_id).name
				end
				#who created the plan 
				plan_creator = User.find_by(id: plan.user_id).fullname

				#is the current_user going 
				if PlanMember.find_by(plan_id: plan.id, user_id: current_user.id)
					going = true  
				else 
					going = false
				end

				#did current user start plan 
				if plan.user_id == current_user.id
					started_it = true
				else
					started_it = false 
				end

				exploding_seconds = [300, 600, 1800, 3600, 14400][plan.exploding_offer].seconds 
				exploding_offer_countdown = exploding_seconds - (DateTime.now.utc - plan.created_at)

				if plan.is_happening || exploding_offer_countdown > 0
					plan_data = {
						plan_id: plan.id,
						group_name: group_name, 
						plan_creator: plan_creator, 
						activity: plan.activity, 
						time: plan.time, 
						exploding_offer_countdown: exploding_offer_countdown, 
						going: going,
						started_it: started_it,
						is_happening: plan.is_happening
					}

					plans_to_show.push(plan_data)
				end
			end

			render json: {plans_to_show: plans_to_show, is_success: true }, status: :ok
		
		end
	end

	##### will send people notification if plan has expired but appears on joiner screen 
	def join_plan 
		require 'fcm'
		activities = ["grab food", "hang out", "group study", "party"]
		plan_member = PlanMember.new(
        	plan_id: params[:plan_id],
        	user_id: current_user.id
        )
		plan = Plan.find_by(id: params[:plan_id])

		if plan_member.save
			PlanMessage.create(
      	plan_id: params[:plan_id],
      	user_id: current_user.id, 
      	content: "#{current_user.fullname} is in!",
      	system_message: true
      )	

      member_count = PlanMember.where(plan_id: params[:plan_id]).count
			is_happening = false
	    if member_count > 2 && plan.is_happening == false
	    	is_happening = true
	    	plan.is_happening = true
	    	plan.save 

	    	PlanMessage.create(
	      	plan_id: params[:plan_id],
	      	user_id: current_user.id, 
	      	content: "Woohoo this plan to #{activities[plan.activity]} is happening! 3 or more people are in.",
	      	system_message: true
	      )	
	    end
	    render json: { is_success: true, is_happening: is_happening, name_of_joiner: current_user.fullname}, status: :ok
		
		else
			render json: { is_success: false }, status: :ok
		end
	end

			##notification stuff
			# plan = Plan.find_by(id: params[:plan_id])
	  #   firebase_tokens = User.joins(:plan_members)
	  #   	.where(plan_members: {user_id: plan.plan_members.pluck(:user_id)})
	  #   	.where.not(plan_members: {user_id: current_user.id})
	  #   	.pluck(:firebase_token)
	  #   	.uniq

	  #   if plan.group_type == "Program"
  	# 		group_name = plan.group.program_name
  	# 	else
  	# 		group_name = plan.group.name
  	# 	end

			#notification data 
	    # registration_ids = firebase_tokens
	    # @notification = {
	    #     title: "#{group_name}",
	    #     body: "#{current_user.fullname} is in!",
	    #     sound: "default"
	    #   }

	    # options = {notification: @notification, priority: 'high', data: {outgoing: true}}
	    # response = fcm.send(registration_ids, options)

	    

	    	#notification data 
	    	# registration_id_second = firebase_tokens.push(current_user.firebase_token)
	    	# @notification = {
	     #    title: "Woohoo it's happening!",
	     #    body: "3 or more people are in to #{activities[plan.activity]} soon.",
	     #    sound: "default"
	     #  }

	    	# options = {notification: @notification, priority: 'high', data: {outgoing: true}}
	    	# response = fcm.send(registration_id_second, options)
	    


	def get_messages
		#check if user belongs to group
		messages = []

		retrieve_all = PlanMessage.includes(:user).where(plan_id: params[:plan_id]).order(:id).reverse #.first.user.fullname
		retrieve_all.each do |message|
			if message.system_message
				output = {
					_id: message.id,
	        text: message.content,
	        createdAt: message.created_at,
	        system: true
				}
			else
				output = {
					_id: message.id,
	        text: message.content,
	        createdAt: message.created_at,
	        user: {
	          _id: message.user.id,
	          name: message.user.fullname
	        }
				}
			end
			messages.push(output)
		end
		render json: { is_success: true, messages: messages}, status: :ok 
	end


end



  # enum activity: %i(grab_food hang_out study party)
  # enum exploding_offer: %i(0:"5 minutes", 1:"10 minutes", 2:"30 minutes", 3:"1 hour", 4:"4 hours")
  # enum time: %i(
  # 0	"12:00AM",
  # 1   "12:30AM",
  # 2    "1:00AM",
  # 3    "1:30AM",
  # 4    "2:00AM",
  # 5    "2:30AM",
  # 6    "3:00AM",
  # 7    "3:30AM",
  # 8    "4:00AM",
  # 9    "4:30AM",
  # 10    "5:00AM",
  # 11    "5:30AM",
  # 12    "6:00AM",
  # 13    "6:30AM",
  # 14    "7:00AM",
  # 15    "7:30AM",
  # 16    "8:00AM",
  # 17    "8:30AM",
  # 18    "9:00AM",
  # 19    "9:30AM",
  # 20    "10:00AM",
  # 21    "10:30AM",
  # 22    "11:00AM",
  # 23    "11:30AM",
  # 24    "12:00PM",
  # 25    "12:30PM",
  # 26    "1:00PM",
  # 27    "1:30PM",
  # 28    "2:00PM",
  # 29    "2:30PM",
  # 30    "3:00PM",
  # 31    "3:30PM",
  # 32    "4:00PM",
  # 33    "4:30PM",
  # 34    "5:00PM",
  # 35    "5:30PM",
  # 36    "6:00PM",
  # 37    "6:30PM",
  # 38    "7:00PM",
  # 39    "7:30PM",
  # 40    "8:00PM",
  # 41    "8:30PM",
  # 42    "9:00PM",
  # 43    "9:30PM",
  # 44    "10:00PM",
  # 45    "10:30PM",
  # 46    "11:00PM",
  # 47    "11:30PM")



class User < ApplicationRecord

	# has_secure_password

	has_many :friendships # returns all friendships where user_id is current user 
	has_many :friends, :through => :friendships # returns frind users object where user_id is current user 
	has_many :inverse_friendships, :class_name => "Friendship", :foreign_key => "friend_id" # returns friendship object 
	has_many :inverse_friends, :through => :inverse_friendships, :source => :user # returns user object where friend_id is current user 

	
	has_many :invitations #invitations sent  invitation object 
	has_many :invitation_recipients, :through => :invitations #friends_i_invited friend objects
	has_many :invitations_received, :class_name => "Invitation", :foreign_key => "invitation_recipient_id" # invitation objects
	has_many :friends_who_invited_me, :through => :invitations_received, :source => :user

	has_many :outgoings
	has_many :feedbacks

	has_many :custom_group_members
	has_one :program_group_member
	has_many :plans
	has_many :plan_members
	has_many :plan_messages

	has_many :text_invitations 
	has_one :calendar 

# needs to be there for university feature 
	# belongs_to :university

	scope :friendship_status, -> (current_user) { joins(:friendships).where(:friendships => {friend_id: current_user, status: "FRIENDSHIP"}).pluck(:fullname, :phone_number, :firebase_token).map { |fullname, phone_number, firebase_token| {fullname: fullname, phone_number: phone_number, firebase_token: firebase_token}} }
	scope :contacts_get_notified, -> (current_user) { where(id: Friendship.all.where(user_id: current_user, status: "FRIENDSHIP", receive_notifications: true, send_notifications: true ).pluck(:friend_id)).pluck(:fullname, :phone_number, :firebase_token).map { |fullname, phone_number, firebase_token| {fullname: fullname, phone_number: phone_number, firebase_token: firebase_token}} }
	scope :friend_requests, -> (current_user) { joins(:friendships).where(:friendships => {friend_id: current_user, status: "WAITING"}).pluck(:fullname, :username, 'friendships.created_at', 'friendships.id').map { |fullname, username, created_at, id| {fullname: fullname, username: username, created_at: created_at, id: id}} }


	validates :username, format: { with: /\A[a-zA-Z0-9]{3,15}\z/ }, allow_nil: true, uniqueness: true
	validates :phone_number, format: { with: /\A[0-9]{10}\z/ }, uniqueness: true
	# validates :email, uniqueness: true



  def generate_authentication_token
    begin
      self.access_token = Devise.friendly_token
    end while self.class.exists?(access_token: access_token)
  end

  def generate_email_code
  	self.email_code = rand(100)*100+rand(100)+rand(9)+rand(9)
  end


end

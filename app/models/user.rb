class User < ApplicationRecord

	# has_secure_password

	has_many :friendships
	has_many :friends, :through => :friendships
	has_many :inverse_friendships, :class_name => "Friendship", :foreign_key => "friend_id"
	has_many :inverse_friends, :through => :inverse_friendships, :source => :user

	has_many :outgoings
	has_many :feedbacks

	has_many :custom_group_members
	has_one :program_group_member
	has_many :plans
	has_many :plan_members
	has_many :plan_messages

	belongs_to :university

	scope :friendship_status, -> (current_user) { joins(:friendships).where(:friendships => {friend_id: current_user, status: "FRIENDSHIP"}).pluck(:fullname, :phone_number, :firebase_token).map { |fullname, phone_number, firebase_token| {fullname: fullname, phone_number: phone_number, firebase_token: firebase_token}} }
	scope :contacts_get_notified, -> (current_user) { where(id: Friendship.all.where(user_id: current_user, status: "FRIENDSHIP", receive_notifications: true, send_notifications: true ).pluck(:friend_id)).pluck(:fullname, :phone_number, :firebase_token).map { |fullname, phone_number, firebase_token| {fullname: fullname, phone_number: phone_number, firebase_token: firebase_token}} }
	scope :friend_requests, -> (current_user) { joins(:friendships).where(:friendships => {friend_id: current_user, status: "WAITING"}).pluck(:fullname, :username, 'friendships.created_at', 'friendships.id').map { |fullname, username, created_at, id| {fullname: fullname, username: username, created_at: created_at, id: id}} }


	validates :username, format: { with: /\A[a-zA-Z0-9]{3,15}\z/ }, allow_nil: true, uniqueness: true
	validates :phone_number, format: { with: /\A[0-9]{10}\z/ }, allow_nil: true
	validates :email, uniqueness: true



  def generate_authentication_token
    begin
      self.access_token = Devise.friendly_token
    end while self.class.exists?(access_token: access_token)
  end

  def generate_email_code
  	self.email_code = rand(100)*100+rand(100)+rand(9)+rand(9)
  end


end

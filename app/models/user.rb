class User < ApplicationRecord

	has_many :friendships
	has_many :friends, :through => :friendships
	has_many :inverse_friendships, :class_name => "Friendship", :foreign_key => "friend_id"
	has_many :inverse_friends, :through => :inverse_friendships, :source => :user

	has_many :outgoings
	has_many :feedbacks

	scope :friendship_status, -> (current_user) { joins(:friendships).where(:friendships => {friend_id: current_user, status: "FRIENDSHIP"}).pluck(:fullname, :phone_number, :firebase_token).map { |fullname, phone_number, firebase_token| {fullname: fullname, phone_number: phone_number, firebase_token: firebase_token}} }
	scope :my_contacts, -> { where(id: Friendship.all.where(user_id: current_user).pluck(:friend_id)).pluck(:fullname, :phone_number, :username).map { |fullname, phone_number, username| {fullname: fullname, phone_number: phone_number, username: username}} }
	scope :friend_requests, -> (current_user) { joins(:friendships).where(:friendships => {friend_id: current_user, status: "WAITING"}).pluck(:fullname, :username, 'friendships.created_at', 'friendships.id').map { |fullname, username, created_at, id| {fullname: fullname, username: username, created_at: created_at, id: id}} }


	validates :username, format: { with: /\A[a-zA-Z0-9]{3,15}\z/ }, allow_nil: true
	validates :phone_number, format: { with: /\A[0-9]{10}\z/ }, allow_nil: true




  def generate_authentication_token
    begin
      self.access_token = Devise.friendly_token
    end while self.class.exists?(access_token: access_token)
  end


end

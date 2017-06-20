class User < ApplicationRecord
  devise :database_authenticatable, :registerable, :recoverable, :rememberable, :trackable, :validatable, :authentication_keys => [:login]
  attr_accessor :login
  enum role: [:client, :editor, :admin]
  after_initialize :set_default_role, if: :new_record?
  validate :validate_username

	def validate_username
		if User.where(email: username).exists?
			errors.add(:username, :invalid)
		end
	end

  private
  def set_default_role
    self.role ||= :client
  end

   def self.find_for_database_authentication(warden_conditions)
     conditions = warden_conditions.dup
     if login = conditions.delete(:login)
       where(conditions.to_h).where(["lower(username) = :value OR lower(email) = :value", { :value => login.downcase }]).first
     elsif conditions.has_key?(:username) || conditions.has_key?(:email)
       where(conditions.to_h).first
     end
   end

end


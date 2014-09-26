class User < ActiveRecord::Base
  
  has_many :audios
  has_many :videos
  has_many :news
  has_many :events
  has_many :authentications
  has_one :cart
  has_many :orders
  
  #mount_uploader :profile_photo, ProfilePhotoUploader
  mount_uploader :music_source_local, MusicSourceLocalUploader
  
  # Include default devise modules. Others available are:
  # :confirmable, :lockable, :timeoutable and :omniauthable
  devise :database_authenticatable, :registerable, :confirmable,
         :recoverable, :rememberable, :trackable, :validatable,
         :omniauthable, :omniauth_providers => [:facebook, :twitter, :google_oauth2]
  
  before_create :setup_default_role_for_new_users       
  ROLES = %w[administrator registered]

  
  def self.find_for_facebook_oauth(auth, signed_in_resource=nil)
    user = User.where(:provider => auth.provider, :uid => auth.uid).first
    unless user
      user = User.create(name:auth.extra.raw_info.name,
                           provider:auth.provider,
                           uid:auth.uid,
                           email:auth.info.email,
                           password:Devise.friendly_token[0,20]
                           )
    end
    user
  end
  
  def self.find_for_twitter_oauth(auth, signed_in_resource=nil)
    user = User.where(:provider => auth.provider, :uid => auth.uid).first
    ## As Twitter doesn't provide user email address, so we can't create a new user
    user
  end
  
  def self.new_with_session(params, session)
    super.tap do |user|
      if data = session["devise.facebook_data"] && session["devise.facebook_data"]["extra"]["raw_info"]
        user.email = data["email"] if user.email.blank?
      end
    end
  end

  private

  def setup_default_role_for_new_users
    if self.role.blank?
      self.role = "registered"
    end
  end

end

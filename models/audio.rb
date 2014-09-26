class Audio < ActiveRecord::Base
  belongs_to :user  
  has_and_belongs_to_many :music_categories
  validates :title, presence: true
  validates :path, presence: true
  validates :price,:allow_blank => true, :numericality => { :only_integer => true,:greater_than_or_equal_to=>0 }
  mount_uploader :path, AudioUploader  
end

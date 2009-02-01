class County < ActiveRecord::Base
  belongs_to :state
  has_many :neighborhoods
  has_many :users
end

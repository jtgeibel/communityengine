class Neighborhood < ActiveRecord::Base
  has_many :users
  belongs_to :county
  belongs_to :state
end

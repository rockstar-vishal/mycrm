class FbAdsId < ActiveRecord::Base

  validates :number, presence: true
  belongs_to :project

end

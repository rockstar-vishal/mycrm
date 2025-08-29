class CampaignsProject < ActiveRecord::Base

  belongs_to :campaign
  belongs_to :project

end

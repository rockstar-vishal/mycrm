class Campaign < ActiveRecord::Base

	belongs_to :company
	belongs_to :source
	validates :title, :start_date, :end_date, :budget, :source_id, presence: true

  has_many :projects, through: :campaigns_projects
  has_many :campaigns_projects, class_name: '::CampaignsProject'

  delegate :name, to: :source, prefix: true, allow_nil: true

end

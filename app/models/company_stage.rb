class CompanyStage < ActiveRecord::Base

  belongs_to :stage

  has_many :company_stage_statuses
  accepts_nested_attributes_for :company_stage_statuses, reject_if: :all_blank, allow_destroy: true

  delegate :name, to: :stage, prefix: true, allow_nil: true


end

class CompanyStageStatus < ActiveRecord::Base

  acts_as_api

  belongs_to :company_stage
  belongs_to :status

  api_accessible :details do |template|
    template.add lambda{|cs| cs&.company_stage&.stage_id  }, as: :id
    template.add lambda{|cs| cs.company_stage&.stage&.name  }, as: :name
  end

end

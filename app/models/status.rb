class Status < ActiveRecord::Base

  include AppSharable

  has_many :company_stage_statuses

  validates :class_name, presence: true
  validates :name, presence: true, uniqueness: { scope: :class_name,
    message: "Status name should be unique for a type" }

  scope :active, -> { where(:active=>true) }
  scope :of_leads, -> { where(:class_name=>"Lead") }
  scope :of_loans, -> { where(:class_name=>"Loan") }
  scope :latest_first, -> { order("company_statuses.created_at asc") }


  def fetch_stages(company)
    company_stage_status = self.company_stage_statuses.joins{:company_stage}.where(company_stage: {company_id: company.id})
    if company_stage_status.present?
      company_stage_status
    else
      []
    end
  end

end

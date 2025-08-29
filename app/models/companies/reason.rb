class Companies::Reason < ActiveRecord::Base
  belongs_to :company
  validates :reason, presence: true

  validates :reason, uniqueness: { scope: :company_id,
    message: "Reason name should be unique for a company" }

  scope :active, -> { where(:active=>true) }
end

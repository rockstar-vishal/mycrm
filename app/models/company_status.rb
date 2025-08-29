class CompanyStatus < ActiveRecord::Base

  belongs_to :company
  belongs_to :status

end

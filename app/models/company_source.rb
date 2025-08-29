class CompanySource < ActiveRecord::Base

  belongs_to :company
  belongs_to :source

end

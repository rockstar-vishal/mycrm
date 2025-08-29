class SubSource < ActiveRecord::Base
  include AppSharable
  belongs_to :company
end

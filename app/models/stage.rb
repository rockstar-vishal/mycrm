class Stage < ActiveRecord::Base

  include AppSharable

  validates :name, presence: true

  scope :active, -> { where(:is_active=>true) }

end

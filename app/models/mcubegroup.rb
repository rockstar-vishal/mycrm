class Mcubegroup < ActiveRecord::Base

  belongs_to :company
  validates :number, presence: true, uniqueness: true

  scope :active, -> { where(is_active: true) }

end

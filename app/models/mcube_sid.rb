class McubeSid < ActiveRecord::Base

  belongs_to :company
  belongs_to :project
  validates :number, presence: true, uniqueness: true

  scope :active, -> { where(is_active: true) }

end

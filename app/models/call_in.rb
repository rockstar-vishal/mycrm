class CallIn < ActiveRecord::Base
  belongs_to :company
  belongs_to :project
  belongs_to :user
  has_many :leads
  validates :number, :company, presence: true

  scope :active, -> { where(:active=>true) }
end

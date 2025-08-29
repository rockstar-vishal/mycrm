class ExportLog < ActiveRecord::Base
  belongs_to :company
  belongs_to :user
  validates :count, presence: true
end

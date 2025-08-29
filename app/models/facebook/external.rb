class Facebook::External < ActiveRecord::Base
  validates :fbpage_id, :endpoint_url, presence: true
  validates :fbpage_id, uniqueness: true
end

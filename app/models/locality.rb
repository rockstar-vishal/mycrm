class Locality < ActiveRecord::Base
  include AppSharable
  include CustomValidations

  belongs_to :region
  validates :name, :region_id, presence: true
  validate :unique_name
  acts_as_api

  api_accessible :details do |t|
    t.add :id
    t.add lambda{|locality| locality.name}, as: :text
    t.add lambda{|locality| locality.region.city.id rescue nil}, as: :city_id
  end

  def self.basic_search(query)
    localities = Locality.joins(:region)
    localities = localities.where('localities.name ILIKE ? or regions.name ILIKE ?', "%#{query}%", "%#{query}%")
    localities
  end

end

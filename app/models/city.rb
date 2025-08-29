class City < ActiveRecord::Base
  include AppSharable
  include CustomValidations
  has_many :regions, dependent: :destroy
  has_many :localities, through: :regions
  validates :name, presence: true

  validate :unique_name

  def self.basic_search(query)
    cities = City.all
    cities = cities.where('cities.name ILIKE ?',"%#{query}%")
    cities
  end
end

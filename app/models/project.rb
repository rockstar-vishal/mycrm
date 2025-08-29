class Project < ActiveRecord::Base

  include AppSharable

  has_many :call_ins, dependent: :restrict_with_error
  has_many :exotel_sids, dependent: :restrict_with_error
  has_many :mcube_sids, dependent: :restrict_with_error
  has_many :fb_forms, class_name: 'Companies::FbForm', dependent: :restrict_with_error
  has_many :users_projects, class_name: 'UsersProject'
  has_many :visits_projects, class_name: 'Leads::VisitsProject'
  has_many :fb_ads_ids, class_name: 'FbAdsId'
  belongs_to :company
  belongs_to :city
  belongs_to :country
  has_many :leads, dependent: :restrict_with_error
  validates :name, :company, presence: true

  scope :active, -> { where(:active=>true) }
  scope :cross_pitch_only, -> { where(:cross_pitch=>true) }

  accepts_nested_attributes_for :fb_ads_ids, reject_if: :all_blank, allow_destroy: true

  def housing_token=(default_value)
    write_attribute(:housing_token, default_value.strip) if default_value.present?
  end

  def mb_token=(default_value)
    write_attribute(:mb_token, default_value.strip) if default_value.present?
  end

  def nine_token=(default_value)
    write_attribute(:nine_token, default_value.strip) if default_value.present?
  end

  def property_codes=(default_value)
    if default_value.present?
      pc = default_value.map{|val| val.gsub(' ','').split(',')}.flatten
      write_attribute(:property_codes, pc)
    end
  end

  class << self

    def basic_search(query)
      projects = Project.includes(:city)
      projects =projects.where("projects.name ILIKE ? OR cities.name ILIKE ?", "%#{query}%", "%#{query}%").references(:city)
      projects
    end
  end

end

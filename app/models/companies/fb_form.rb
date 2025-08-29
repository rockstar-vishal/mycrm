class Companies::FbForm < ActiveRecord::Base
  belongs_to :company, class_name: "::Company"
  belongs_to :project, class_name: "::Project"
  belongs_to :fb_page, class_name: "::Companies::FbPage"
  belongs_to :campaign, class_name: "Campaign"
  validates :project, :form_no, :fb_page, :title, presence: true
  validates_uniqueness_of :form_no

  scope :active, -> { where(:active=>true) }

  def form_fields
    graph = ::Koala::Facebook::API.new(self.fb_page.access_token)
    fb_response = graph.get_object(self.form_no, {"fields"=>"questions.fields(key,label)"})
    return fb_response["questions"].as_json(only: ["key", "label"])
  end

  def to_param
   form_no
  end


  OTHER_DATA = [
    :customer_type
  ]

  def default_fields_values
    self.other_data || {}
  end


  OTHER_DATA.each do |method|
    define_method("#{method}=") do |val|
      self.other_data_will_change!
      self.other_data = (self.other_data || {}).merge!({"#{method}" => val})
    end
    define_method("#{method}") do
      default_fields_values.dig("#{method}")
    end
  end


  class << self
    def get_company_uuid_from_form form_no
      company = all.find_by(:form_no=>form_no).company rescue nil
      if company.present?
        return company.fb_access_token, company.uuid
      else
        return nil,nil
      end
    end
  end
end

class Companies::FbPage < ActiveRecord::Base
  has_many :fb_forms, class_name: "::Companies::FbForm"
  validates :access_token, :page_fbid, presence: true, uniqueness: true
  belongs_to :company

  def leadgen_forms
    graph = ::Koala::Facebook::API.new(self.access_token)
    begin
      fb_response = graph.get_object("#{self.page_fbid}/leadgen_forms")
      return true, fb_response.as_json(only: ["id", "name"])
    rescue Exception => e
      return false, e
    end
  end

  class << self
    def extend_token token
      status, data = ::FbSao.extend_token token
      if status
        return data["access_token"]
      else
        return data
      end
    end
  end

end

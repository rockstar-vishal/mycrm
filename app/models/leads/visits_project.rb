class Leads::VisitsProject < ActiveRecord::Base

  belongs_to :leads_visit, :class_name=>"Leads::Visit"
  belongs_to :project

end

module LeadRequirements

  extend ActiveSupport::Concern

  included do
    has_attached_file :booking_form,
                    path: ":rails_root/public/system/:attachment/:id/:style/:filename",
                    url: "/system/:attachment/:id/:style/:filename"

    validates_attachment_content_type  :booking_form,
                        content_type: ['application/pdf', 'application/msword', 'image/jpeg', 'image/png', 'application/vnd.ms-excel',
                          'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet'],
                        size: { in: 0..2.megabytes }
    enum customer_type:{
      "B2E": 1,
      "B2C": 2
    }
    PROPERTY_TYPES = ["Residential", "Commercial"]
    RESIDENTIAL_PROPERTY_TYPES = ["Flat", "Bungalow", "Row-House", "Plot"]
    COMMERCIAL_PROPERTY_TYPES = ["Shop", "Office", "Showroom","Plot"]
    PURPOSE = ["Investment", "Enduse"]
    UNITS = ["Sq.Ft", "Sq.Mt", "Acres"]
    PLOT_UNITS = ["Sq.Ft", "Sq.Mt"]
    PROPERTY_CONFIGURATION = ["1bhk", "2bhk", "3bhk", "4bhk", "5bhk", "5+bhk"]
    STAGES = ['Active', 'Inactive', 'Booked', 'Dead']
    DIGITALSUBSOURCES=["Website","99 Acres","Magic Bricks","Housing.com","FB","Insta","google"]
    has_one :residential_type
    has_one :commercial_type

    accepts_nested_attributes_for :residential_type, allow_destroy: true
    accepts_nested_attributes_for :commercial_type, allow_destroy: true

  end
end
module CustomFields

  extend ActiveSupport::Concern

  included do

    has_attached_file :logo, :styles => { :small => "180x180#", :thumb => "70x70#" }, path: ":rails_root/public/system/:attachment/:id/:style/:filename",url: "/system/:attachment/:id/:style/:filename"
    validates_attachment  :logo, :content_type => { :content_type => %w(image/jpeg image/jpg image/png) }, :size => { :in => 0..1.megabytes }
    has_attached_file :icon, :styles => { :small => "180x180#", :thumb => "70x70#" }, path: ":rails_root/public/system/:attachment/:id/:style/:filename",url: "/system/:attachment/:id/:style/:filename"
    validates_attachment  :icon, :content_type => { :content_type => %w(image/jpeg image/jpg image/png) }, :size => { :in => 0..1.megabytes }
    has_attached_file :favicon, :styles => { :small => "180x180#", :thumb => "70x70#" }, path: ":rails_root/public/system/:attachment/:id/:style/:filename",url: "/system/:attachment/:id/:style/:filename"
    validates_attachment  :favicon, :content_type => { :content_type => %w(image/jpeg image/jpg image/png) }, :size => { :in => 0..1.megabytes }

    ['dead_status', 'new_status', 'expected_site_visit', 'booking_done', 'hot_status', 'site_visit_done','token_status'].each do |status|
      belongs_to "#{status}".to_sym, class_name: 'Status', foreign_key: "#{status}_id"
      delegate :name, to: "#{status}", allow_nil: true, prefix: true
    end

    class << self

      def allowed_options
        ::Lead.column_names - ["id", "company_id", "created_at", "updated_at", "lead_no", "ncd", "comment", "status_id", "source_id", "date"]
      end

      def detail_fields
        ::Lead.column_names - ["id", "company_id", "updated_at"]
      end

      def required_options
        ::Lead.column_names - ["id", "created_at", "updated_at", "company_id"]
      end

      def broker_required_options
        ::Broker.column_names - ["id", "created_at", "updated_at", "company_id"]
      end

      def visits_allowed_options
        ::Leads::Visit.column_names - ["id", "date", "created_at", "updated_at", "lead_id",  "site_visit_form_file_name", "site_visit_form_content_type", "site_visit_form_file_size", "site_visit_form_updated_at"] + (Leads::VisitsProject.column_names - ["id", "visit_id"])
      end

      def custom_label_options
        ::Lead.column_names - ["id", "company_id", "created_at", "updated_at", "lead_no", "ncd", "comment", "status_id", "source_id", "date", "email", "mobile", "date", "other_phones", "other_emails", "user_id", "address", "city_id", "country", "state", "budget", "uuid", "dead_reason_id", "sub_source", "tentative_visit_planned", "dead_sub_reason", "name", "visit_date", "visit_comments", "call_in_id", "conversion_date", "broker_id", "property_type", "stage", "other_data", "presale_stage_id", "presale_user_id"]
      end
    end
  end

  def is_allowed_field?(field)
    self.allowed_fields.include?(field)
  end

  def is_pop_fields?(field)
    self.popup_fields.include?(field)
  end

  def is_required_fields?(field)
    self.required_fields.include?(field)
  end

  def is_allowed_for_visits?(field)
    self.visits_allowed_fields.include?(field)
  end

  def find_dead_reason reason
    self.reasons.where("companies_reasons.reason ILIKE ?", reason.downcase).first
  end

  def find_label(key)
    self.custom_labels.find_by_key(key)
  end

end

class Leads::Visit < ActiveRecord::Base

  belongs_to :lead
  belongs_to :user
  has_many :visits_projects, class_name: 'Leads::VisitsProject'
  has_many :projects, class_name: '::Project', through: :visits_projects
  validates :date, presence: true

  has_attached_file :site_visit_form,
                    path: ":rails_root/public/system/:attachment/:id/:style/:filename",
                    url: "/system/:attachment/:id/:style/:filename"

  validates_attachment_content_type  :site_visit_form,
                        content_type: ['application/pdf', 'application/msword', 'image/jpeg', 'image/png', 'application/vnd.ms-excel',
                          'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet'],
                        size: { in: 0..2.megabytes }
  BANK_NAMES = ["Axis Bank","Bank of Baroda", "Citi Bank", "City Union Bank","Indian Bank", "Indian Overseas Bank","ICICI", "HDFC","Punjab National Bank","State Bank of India"]
  after_create :set_lead_revisit
  validate :check_postpone_date

  scope :executed, -> { where(:is_visit_executed=>true) }

  delegate :name, to: :user, allow_nil: true, prefix: true


  def check_postpone_date
    company = self.lead.company
    if company.setting.present? && company.enable_advance_visits
      if self.is_postponed && self.changes.present? && self.changes["is_postponed"].present?
        if self.changes.present? && !self.changes["date"].present?
          errors.add(:date, 'Add postponed date')
        end
      end
    end
  end

  def file_url
    if self.site_visit_form.present?
      self.site_visit_form.url
    end
  end

  def set_lead_revisit
    if self.lead.visits.count > 1
      unless self.lead.revisit
        self.lead.update_attributes(revisit: true)
      end
    end
  end
end

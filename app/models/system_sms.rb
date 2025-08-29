class SystemSms < ActiveRecord::Base
  validates :mobile, :text, presence: true
  belongs_to :company
  belongs_to :user
  belongs_to :messageable, polymorphic: true
  scope :successful, -> { where(:sent=>true) }
  scope :of_leads, -> { where(:messageable_type=>"Lead") }

  after_commit :send_sms, on: :create

  def send_sms
    Resque.enqueue(ProcessSystemSms, self.id)
    if self.company.mobicomm_sms_service_enabled
      Resque.enqueue(LeadRegistration, self.id)
    end
  end
end

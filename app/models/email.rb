class Email < ActiveRecord::Base

  validates :subject, presence: true

  belongs_to :sender, polymorphic: true
  belongs_to :receiver, polymorphic: true

  after_commit :send_email, on: :create


  def send_email
    Resque.enqueue(ProcessEmail, self.id)
  end

end

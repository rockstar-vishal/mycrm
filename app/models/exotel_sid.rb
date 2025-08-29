class ExotelSid < ActiveRecord::Base
  belongs_to :company
  belongs_to :project
  belongs_to :source

  validates :number, presence: true, uniqueness: true

  validates :source_id, presence: true, if: :only_inbound_service

  scope :active, -> { where(is_active: true) }
  scope :inbound_numbers, -> { where(only_inbound_service: true) }


  def find_round_robin_user
    round_robin_ids = self.default_numbers
    user_ids = company.users.where(mobile: round_robin_ids).ids rescue []
    leads = self.company.leads.joins{call_logs}.where("leads_call_logs.other_data->>'phone_number_sid' = ?", self.number)
    lead_user_id = leads.last&.user_id
    if user_ids.include? lead_user_id
      user_ids.each_with_index do |u, index|
        if(lead_user_id == u)
          if(index == user_ids.size - 1)
            return user_ids[0]
          else
            return user_ids[index+1]
          end
        end
      end
    else
      user_ids[0] || self.company.users.active.superadmins.first.id
    end

  end

end

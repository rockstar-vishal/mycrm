class Loan < ActiveRecord::Base
  DEFAULT_STATUS = 20
  DEAD_LOAN_IDS = [21]
  BOOKED_LOAN_IDS = [27]
  HOT_STATUS_ID = 23
  belongs_to :company
  belongs_to :lead
  belongs_to :user
  belongs_to :status

  validates_uniqueness_of :lead_id

  scope :backlogs_for, -> (company){where("loans.ncd IS NULL OR loans.ncd <= ?", Time.zone.now).actives}
  scope :todays_calls, -> {where("loans.ncd BETWEEN ? AND ?",Date.today.beginning_of_day, Date.today.end_of_day)}
  scope :actives, -> {where.not(:status_id=>[DEAD_LOAN_IDS, BOOKED_LOAN_IDS].flatten)}

  class << self
    def user_loans(user)
      loans = user.manageable_loans.actives
      return loans
    end

    def basic_search(search_string, user)
      leads = all.joins{lead}.where("leads.email ILIKE :term OR leads.mobile LIKE :term OR leads.name ILIKE :term OR leads.lead_no ILIKE :term", :term=>"%#{search_string}%")
    end

    def search_base_loans(user)
      return user.manageable_loans
    end

    def user_loans(user)
      loans = user.manageable_loans.actives
      return loans
    end

    def advance_search(search_params, user)
      loans = all.joins{lead}
      if search_params["ncd_from"].present?
        next_call_date_from = Time.zone.parse(search_params["ncd_from"]).at_beginning_of_day
      end
      if search_params["ncd_upto"].present?
        next_call_date_upto = Time.zone.parse(search_params["ncd_upto"]).at_end_of_day
      end
      if search_params["created_at_from"].present?
        created_at_from = Time.zone.parse(search_params["created_at_from"]).at_beginning_of_day
      end
      if search_params["created_at_upto"].present?
        created_at_upto = Time.zone.parse(search_params["created_at_upto"]).at_end_of_day
      end
      if search_params["visited_date_from"].present?
        visited_date_from = Date.parse(search_params["visited_date_from"])
      end
      if search_params["visited_date_upto"].present?
        visited_date_upto = Date.parse(search_params["visited_date_upto"])
      end
      if search_params["loan_users"].present?
        loans = loans.where(:user_id=>search_params["loan_users"])
      end
      if search_params["lead_users"].present?
        loans = loans.where("leads.user_id IN (?)", search_params["lead_users"])
      end
      if search_params["lead_no"].present?
        loans = loans.where("leads.lead_no = ?", search_params["lead_no"])
      end
      if search_params["name"].present?
        loans = loans.where("leads.name ILIKE ?", "%#{search_params["name"]}%")
      end
      if search_params["backlogs_only"].present?
        loans = loans.backlogs_for(user.company)
      end
      if search_params["todays_call_only"].present?
        loans = loans.actives.todays_calls
      end
      if search_params["lead_statuses"].present?
        loans = loans.where("leads.status_id IN (?)", search_params["lead_statuses"] )
      end
      if search_params["loan_statuses"].present?
        loans = loans.where(:status_id=>search_params["loan_statuses"])
      end
      if search_params["dead_reasons"].present?
        loans = loans.where(status_id: DEAD_LOAN_IDS, dead_reason_id: search_params["dead_reasons"])
      end
      if created_at_from.present?
        loans = loans.where("loans.created_at >= ?", created_at_from)
      end
      if created_at_upto.present?
        loans = loans.where("loans.created_at <= ?", created_at_upto)
      end
      if next_call_date_from.present?
        loans = loans.where("loans.ncd >= ?", next_call_date_from)
      end
      if next_call_date_upto.present?
        loans = loans.where("loans.ncd <= ?", next_call_date_upto)
      end
      if visited_date_from.present?
        leads = loans.joins{lead.visits}.where("leads_visits.date >= ?", visited_date_from)
      end
      if visited_date_upto.present?
        leads = leads.joins{lead.visits}.where("leads_visits.date <= ?", visited_date_upto)
      end
      if search_params["visited"].present? && search_params["visited"] == "true"
        loans = loans.joins{lead.visits}
      end

      if search_params["email"].present?
        loans = loans.where("leads.email ILIKE ?", "%#{search_params["email"]}%" )
      end
      if search_params["mobile"].present?
        loans = loans.where("leads.mobile ILIKE ?", "%#{search_params["mobile"]}%" )
      end
      if search_params["other_phones"].present?
        loans = loans.where("leads.other_phones ILIKE ?", "%#{search_params["other_phones"]}%" )
      end
      if search_params["project_ids"].present?
        loans = loans.where("leads.project_id IN (?)", search_params["project_ids"])
      end
      if search_params["comment"].present?
        loans = loans.where("loans.comment ILIKE ?", "%#{search_params["comment"]}%")
      end
      if search_params["source_ids"].present?
        loans = loans.where("leads.source_id = ?", search_params["source_ids"])
      end
      return loans
    end

    def to_csv(options = {}, exporting_user)
      CSV.generate(options) do |csv|
        exportable_fields = ['Customer Name', 'Lead Number', 'Lead Source', 'Project', 'Lead User', 'Lead Status', 'Lead NCD', 'Lead Comment', 'Loan User', 'Loan Status', 'Loan Dead Reason', 'Loan Dead Sub Reason', 'Loan NCD', 'Loan Comment', 'Lead Created At', 'Loan Referred At']
        if exporting_user.is_super?
          exportable_fields << 'Mobile'
          exportable_fields << 'Email'
        end
        
        csv << exportable_fields

        all.includes{lead.project}.each do |loan|
          lead = loan.lead
          dead_reason = ""
          dead_sub_reason = ""
          if DEAD_LOAN_IDS.include?(loan.status_id)
            dead_reason = loan.dead_reason&.reason
            dead_sub_reason = loan.dead_sub_reason
          end
          final_phone = lead.mobile
          final_email = lead.email
          final_source =(lead.source.name rescue "-")

          this_exportable_fields = [ lead.name, lead.lead_no, final_source, (lead.project.name rescue '-'),(lead.user.name rescue '-'), lead.status.name, (lead.ncd.strftime("%d %B %Y") rescue nil), lead.comment, (loan.user.name rescue '-'), loan.status.name, loan.dead_reason, loan.dead_sub_reason, (loan.ncd.strftime("%d %B %Y") rescue nil), (loan.comment), (lead.created_at.in_time_zone.strftime("%d %B %Y : %I.%M %p") rescue nil), (loan.created_at.in_time_zone.strftime("%d %B %Y : %I.%M %p") rescue nil)]
          if exporting_user.is_super?
            this_exportable_fields << final_phone
            this_exportable_fields << final_email
          end
          csv << this_exportable_fields
        end
      end
    end
  end

  def comment=(default_value)
    if default_value.present?
      comment = "#{self.comment_was} \n #{Time.zone.now.strftime("%d-%m-%y %H:%M %p")} (#{(Lead.current_user.name rescue nil)}) : #{default_value}"
      write_attribute(:comment, comment)
    end
  end
end

require 'active_support/concern'

module LeadApiAttributes

  extend ActiveSupport::Concern

  included do

    acts_as_api

    api_accessible :details do |template|
      template.add :uuid
      template.add :name
      template.add lambda{|lead| lead.status&.name  }, as: :status
      template.add lambda{|lead| lead.project&.name  }, as: :project
      template.add lambda{|lead| lead.source&.name  }, :as => :source
      template.add lambda{|lead| (lead.ncd.strftime("%d %B %Y %I:%M%p") rescue nil) }, as: :ncd
      template.add lambda{|lead| (lead.tentative_visit_planned.strftime("%d %B %Y %I:%M%p") rescue nil) }, as: :tentative_visit_planned
    end
    api_accessible :meta_details_with_detail, extend: :details do |template|
      template.add :email
      template.add :mobile
      template.add :lead_no
      template.add :other_phones
      template.add :ctoc_enabled
      template.add :status_id
      template.add :source_id
      template.add :address
      template.add :city_id
      template.add :sub_source
      template.add :enquiry_sub_source_id
      template.add :broker_id
      template.add :user_id
      template.add :closing_executive
      template.add lambda{|l| l.postsale_user&.name}, as: :closing_executive_name
      template.add :project_id
      template.add :dead_reason_id
      template.add :presale_stage_id
      template.add :lease_expiry_date
      template.add :token_date
      template.add :referal_name
      template.add :referal_mobile
      template.add lambda{|lead| (lead.token_date.strftime("%d %B %Y") rescue nil)}, as: :formatted_token_date
      template.add :booking_date
      template.add lambda{|lead| (lead.booking_date.strftime("%d %B %Y") rescue nil)}, as: :formatted_booking_date
      template.add lambda{|lead| lead.file_url rescue ""}, as: :booking_form
      template.add lambda {|lead| (lead.broker&.name rescue "")}, as: :broker
      template.add lambda{|lead| (lead.lease_expiry_date.strftime("%d %B %Y") rescue nil) }, as: :formatted_expiry_date
      template.add lambda{|lead| lead.dead_reason.reason rescue "" }, as: :dead_reason
      template.add lambda{|lead| lead.is_booked? ? lead.conversion_date&.strftime("%d %B %Y") : nil }, as: :conversion_date
      template.add lambda{|lead| lead.created_at.strftime("%d %B %Y") }, as: :created_at
      template.add lambda{|lead| lead.updated_at.strftime("%d %B %Y") }, as: :updated_at
      template.add lambda{|lead| lead.user&.name  }, as: :assigned_to
      template.add lambda{|lead| lead.city&.name}, as: :city
      template.add lambda{|lead| lead.broker&.name}, as: :broker
      template.add lambda{|lead| lead.visit_fields  }, as: :visits
      template.add :planned_visits
      template.add lambda {|lead| lead.stage&.name }, as: :stage_name
      template.add lambda{|lead| lead.enq_subsource&.name}, as: :enquiry_sub_source
      template.add lambda{|lead| lead.comment.gsub(/\n/, '<br/>').html_safe rescue ""}, as: :comments
      template.add :magic_field_values
      template.add lambda {|l| l.ncd}, as: :next_call_date
      template.add :magic_fields_attributes
      template.add :broker_detail
    end

    def magic_fields_attributes
      send_data = {}
      self.company.magic_fields.each do |field|
        send_data[:"#{field.name}"] = self.send("#{field.name}")
      end
      send_data
    end

    def broker_detail
      self.broker.as_json(only: [:id, :name, :rera_number, :locality, :firm_name, :email, :mobile])
    end

    api_accessible :lead_event do |template|
      template.add :id
      template.add lambda{|lead| lead.name }, as: :title
      template.add lambda{|lead| lead.ncd.strftime("%d %b %Y %I:%M %p") rescue nil }, as: :start
    end

    api_accessible :event do |template|
      template.add :id
      template.add lambda{|lead| lead.name }, as: :title
      template.add lambda{|lead| lead.tentative_visit_planned.strftime("%d %b %Y %I:%M %p") rescue nil }, as: :start
    end

    def planned_visits
      to_send_data = []
      if self.visits.present?
        if self.company.setting.present? && self.company.enable_advance_visits
          visits = self.visits.where.not(is_visit_executed: true)
          visits.each do |visit|
            to_send_data << {
              id: visit.id,
              lead_id: visit.lead.id,
              date: visit.date,
              url: visit.file_url,
              is_visit_executed: visit.is_visit_executed,
              is_postponed: visit.is_postponed,
              is_canceled: visit.is_canceled,
              comment: visit.comment,
              created_at: visit.created_at,
              updated_at: visit.updated_at,
            }
          end
        end
        return to_send_data
      end
    end

    def visit_fields
      to_send_data = []
      if self.visits.present?
        if self.company.setting.present? && self.company.enable_advance_visits
          visits = self.visits.where(is_visit_executed: true)
          visits.each do |visit|
            to_send_data << {
              id: visit.id,
              lead_id: visit.lead.id,
              date: visit.date,
              url: visit.file_url,
              is_visit_executed: visit.is_visit_executed,
              is_postponed: visit.is_postponed,
              is_canceled: visit.is_canceled,
              comment: visit.comment,
              created_at: visit.created_at,
              updated_at: visit.updated_at,
            }
          end
        else
          self.visits.each do |visit|
            to_send_data << {
              id: visit.id,
              lead_id: visit.lead.id,
              date: visit.date,
              url: visit.file_url,
              is_visit_executed: visit.is_visit_executed,
              is_postponed: visit.is_postponed,
              comment: visit.comment,
              created_at: visit.created_at,
              updated_at: visit.updated_at,
              location: visit.location,
              surronding: visit.surronding,
              finalization_period: visit.finalization_period,
              loan_sanctioned: visit.loan_sanctioned,
              bank_name: visit.bank_name,
              loan_amount: visit.loan_amount,
              eligibility: visit.eligibility,
              own_contribution_minimum: visit.own_contribution_minimum,
              own_contribution_maximum: visit.own_contribution_maximum,
              loan_requirements: visit.loan_requirements
            }
          end
        end
        return to_send_data
      end
    end

  end


end
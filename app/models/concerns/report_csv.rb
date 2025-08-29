module ReportCsv

  extend ActiveSupport::Concern

  included do
    class << self

      def report_to_csv(options = {},user)
        data = all.group("user_id, status_id").select("COUNT(*), user_id, status_id, json_agg(leads.id) as lead_ids")
        @data = data.as_json
        users = user.manageables.where(:id=>data.map(&:user_id).uniq)
        statuses = user.company.statuses.where(:id=>data.map(&:status_id).uniq)
        CSV.generate(options) do |csv|
          exportable_fields = ['User Name', 'User Role', 'Total Count' ]
          statuses.each do |status|
            exportable_fields << status.name
          end
          csv << exportable_fields
          users.each do |user|
            this_user_data = @data.select{|k| k["user_id"] == user.id}
            if this_user_data.present?
              user_total = (this_user_data.map{|k| k["lead_ids"].count}.sum rescue nil)
              this_exportable_fields = [user.name, user.role.name, user_total]
              statuses.each do |status|
                this_status_data = this_user_data.detect{|k| k["status_id"] == status.id}
                this_exportable_fields << (this_status_data["lead_ids"].count rescue nil)
              end
            end
            csv << this_exportable_fields
          end
        end
      end

      def campaign_report_to_csv(options={}, user)
        leads = all.where(:user_id=>user.manageable_ids)
        campaigns = user.company.campaigns
        booking_data = leads.booked_for(user.company)
        visted_data = leads.joins{visits}.uniq
        CSV.generate(options) do |csv|
          exportable_fields = ['Title', 'Start Date', 'End Date', 'Budget', 'Source', 'Leads', 'Booked Leads', 'Cost per Lead', 'Visits', 'Cost Per Visit', 'Cost Per Booking' ]
          csv << exportable_fields
          campaigns.each do |campaign|
            this_exportable_fields = [campaign.title, campaign.start_date&.strftime("%Y-%m-%d"), campaign.end_date&.strftime("%Y-%m-%d"), Utility.to_words(campaign.budget), campaign.source_name]
            leads_count = leads.where(source_id: campaign.source_id, created_at: campaign.start_date.beginning_of_day..campaign.end_date.end_of_day).count
            this_exportable_fields << leads_count
            booked_leads_count = booking_data.where(source_id: campaign.source_id, created_at: campaign.start_date.beginning_of_day..campaign.end_date.end_of_day).count
            this_exportable_fields << booked_leads_count
            if leads_count > 0
              cost_per_lead = Utility.to_words(campaign.budget/leads_count)
            else
              cost_per_lead = 'N/A'
            end
            this_exportable_fields << cost_per_lead
            visit_leads_count = visted_data.where(source_id: campaign.source_id, created_at: campaign.start_date.beginning_of_day..campaign.end_date.end_of_day).count
            this_exportable_fields << visit_leads_count
            if visit_leads_count > 0
              cost_per_visit = Utility.to_words(campaign.budget/visit_leads_count)
            else
              cost_per_visit = "N/a"
            end
            this_exportable_fields << cost_per_visit
            if booked_leads_count > 0
              cost_per_book = Utility.to_words(campaign.budget/booked_leads_count)
            else
              cost_per_book = 'N/A'
            end
            this_exportable_fields << cost_per_book
            csv << this_exportable_fields
          end
        end
      end

      def visits_to_csv(options={}, user, start_date, end_date)
        leads = all.joins{visits}.where("leads_visits.date BETWEEN ? AND ?", start_date.to_date, end_date.to_date)
        users = user.manageables.where(:id=>leads.map(&:user_id))
        statuses = user.company.statuses.where(:id=>leads.map(&:status_id))
        CSV.generate(options) do |csv|
          exportable_fields = ['User', 'Total']
          statuses.each do |status|
            exportable_fields << status.name
          end
          csv << exportable_fields
          users.each do |user|
            this_user_data = leads.where(:user_id=>user.id)
            if this_user_data.present?
              user_total = this_user_data.count
              this_exportable_fields = [user.name, user_total]
              statuses.each do |status|
                this_status_data = this_user_data.where(:status_id=>status.id)
                this_exportable_fields << this_status_data.count
              end
            end
            csv << this_exportable_fields
          end
        end
      end

      def activity_to_csv(options={}, user, start_date, end_date)
        activities = user.company.associated_audits.where(:created_at=>start_date..end_date)
        unless user.is_super?
          activities = activities.where(:user_id=>user.manageable_ids, :user_type=>"User")
        end
        lead_ids = activities.pluck(:auditable_id)
        leads = user.manageable_leads.where(:id=>lead_ids.uniq)
        activities = activities.where(:auditable_id=>leads.ids.uniq)
        status_edits = activities.where("audits.audited_changes ->> 'status_id' != ''").group("user_id").select("user_id, json_agg(audited_changes) as change_list")
        comment_edits = activities.where("audits.audited_changes ->> 'comment' != ''").group("user_id").select("user_id, json_agg(audited_changes) as change_list")
        unique_activities = activities.select("DISTINCT ON (audits.auditable_id) audits.* ")
        users = user.manageables.where(:id=>(status_edits.map(&:user_id).uniq | comment_edits.map(&:user_id).uniq))
        status_edits = status_edits.as_json
        comment_edits = comment_edits.as_json
        CSV.generate(options) do |csv|
          exportable_fields = ['User', 'Total Edits', 'Status Edits', 'Comment Edits', 'Unique Leads Edits']
          csv << exportable_fields
          users.each do |user|
            comment_edits = comment_edits.detect{|k| k["user_id"] == user.id}
            status_edits = status_edits.detect{|k| k["user_id"] == user.id}
            uniq_leads_edits = (unique_activities.where(user_id: user.id).map(&:auditable_id).count rescue 0)
            comment_edits_total = (comment_edits["change_list"].count rescue 0)
            status_edits_total = (status_edits["change_list"].count rescue 0)
            total_edits = comment_edits_total + status_edits_total
            this_exportable_fields = [user.name, total_edits, status_edits_total, comment_edits_total, uniq_leads_edits]
            csv << this_exportable_fields
          end
        end
      end

      def source_report_to_csv(options={}, user)
        data = all.group("source_id, status_id").select("COUNT(*), source_id, status_id, json_agg(leads.id) as lead_ids")
        @data = data.as_json(except: [:id])
        sources = user.company.sources.where(:id=>data.map(&:source_id).uniq)
        statuses = user.company.statuses.where(:id=>data.map(&:status_id).uniq)
        CSV.generate(options) do |csv|
          exportable_fields = ['Source', 'Total']
          statuses.each do |status|
            exportable_fields << status.name
          end
          csv << exportable_fields
          sources.each do |source|
            this_source_data = @data.select{|k| k["source_id"] == source.id}
            if this_source_data.present?
              source_total = (this_source_data.map{|k| k["lead_ids"].count}.sum rescue nil)
              this_exportable_fields = [source.name, source_total]
              statuses.each do |status|
                this_status_data = this_source_data.detect{|k| k["status_id"] == status.id}
                this_exportable_fields << (this_status_data["lead_ids"].count rescue nil)
              end
            end
            csv << this_exportable_fields
          end
        end
      end

      def backlog_report_to_csv(options={}, user)
        company = user.company
        leads = all.backlogs_for(company)
        data = leads.group("user_id, status_id").select("COUNT(*), user_id, status_id, json_agg(leads.id) as lead_ids")
        statuses = user.company.statuses.where(:id=>data.map(&:status_id).uniq)
        users = user.manageables.where(:id=>data.map(&:user_id).uniq)
        @data = data.as_json
        CSV.generate(options) do |csv|
          exportable_fields = ['User', 'Total']
          statuses.each do |status|
            exportable_fields << status.name
          end
          csv << exportable_fields
          users.each do |user|
            this_user_data = @data.select{|k| k["user_id"] == user.id}
            user_total = (this_user_data.map{|k| k["lead_ids"].count}.sum rescue 0)
            this_exportable_fields = [user.name, user_total]
            statuses.each do |status|
              this_status_data = this_user_data.detect{|k| k["status_id"] == status.id}
              this_exportable_fields << (this_status_data["lead_ids"].count rescue 0)
            end
            puts this_exportable_fields
            csv << this_exportable_fields
          end
        end
      end

      def project_report_to_csv(options={}, user)
        data = all.group("project_id, status_id").select("COUNT(*), project_id, status_id, json_agg(leads.id) as lead_ids")
        uniq_projects = all.map{|k| k[:project_id]}.uniq
        uniq_statuses = all.map{|k| k[:status_id]}.uniq
        projects = user.company.projects.where(:id=>uniq_projects)
        statuses = user.company.statuses.where(:id=>uniq_statuses)
        @data = data.as_json(except: [:id])
        CSV.generate(options) do |csv|
          exportable_fields = ['Project', 'Total']
          statuses.each do |status|
            exportable_fields << status.name
          end
          csv << exportable_fields
          projects.each do |project|
            this_project_data = @data.select{|k| k["project_id"] == project.id}
            if this_project_data.present?
              project_total = (this_project_data.map{|k| k["lead_ids"].count}.sum rescue nil)
              this_exportable_fields = [project.name, project_total]
              statuses.each do |status|
                this_status_data = this_project_data.detect{|k| k["status_id"] == status.id}
                this_exportable_fields << (this_status_data["lead_ids"].count rescue nil)
              end
            end
            csv << this_exportable_fields
          end
        end
      end

      def dead_report_to_csv(options={}, user)
        leads = all.where(:status_id=>user.company.dead_status_ids)
        reasons = user.company.reasons.where(:id=>leads.map(&:dead_reason_id).uniq)
        users = user.manageables.where(:id=>leads.map(&:user_id).uniq)
        CSV.generate(options) do |csv|
          exportable_fields = ['User', 'Total']
          reasons.each do |reason|
            exportable_fields << reason.reason
          end
          csv << exportable_fields
          users.each do |user|
            this_user_data = leads.where(:user_id=>user.id)
            user_total = this_user_data.count
            this_exportable_fields = [user.name, user_total]
            reasons.each do |reason|
              this_reason_data = this_user_data.where(:dead_reason_id=>reason.id)
              this_exportable_fields << this_reason_data.count
            end
            csv << this_exportable_fields
          end
        end
      end

      def closing_executive_to_csv(options = {},user)
        data = all.group("closing_executive, status_id").select("COUNT(*), closing_executive, status_id, json_agg(leads.id) as lead_ids")
        @data = data.as_json
        users = user.manageables.where(:id=>data.map(&:closing_executive).uniq)
        statuses = user.company.statuses.where(:id=>data.map(&:status_id).uniq)
        CSV.generate(options) do |csv|
          exportable_fields = ['User Name', 'User Role', 'Total Count' ]
          statuses.each do |status|
            exportable_fields << status.name
          end
          csv << exportable_fields
          users.each do |user|
            this_user_data = @data.select{|k| k["closing_executive"] == user.id}
            if this_user_data.present?
              user_total = (this_user_data.map{|k| k["lead_ids"].count}.sum rescue nil)
              this_exportable_fields = [user.name, user.role.name, user_total]
              statuses.each do |status|
                this_status_data = this_user_data.detect{|k| k["status_id"] == status.id}
                this_exportable_fields << (this_status_data["lead_ids"].count rescue nil)
              end
            end
            csv << this_exportable_fields
          end
        end
      end

    end

  end
end
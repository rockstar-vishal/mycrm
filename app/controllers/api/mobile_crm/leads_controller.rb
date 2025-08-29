module Api
  module MobileCrm
    class LeadsController < ::Api::MobileCrmController

      before_action :find_accessible_leads

      before_action :find_lead, only: [:show, :update, :delete_visit, :log_call_attempt, :log_call_attempt, :make_call, :histories]
      before_action :create_call_attempt, only: :make_call
      PER_PAGE = 20

      def index
        if params[:bs].present?
          @leads = @leads.basic_search(params[:bs], @current_app_user)
        end
        if params[:as].present?
          if params[:ss_id].present?
            ss = @current_app_user.search_histories.find(params[:ss_id])
            @leads = @leads.advance_search(ss.search_params, @current_app_user)
          else
            @leads = @leads.advance_search(search_params, @current_app_user)
          end
        end
        if params[:bs].blank? && params[:as].blank?
          @leads = @leads.active_for(@current_app_user.company)
        end
        if params["key"].present? && params["sort"].present?
          if current_user.company.setting.present? && current_user.company.enable_ncd_sort_nulls_last && params['sort'] == "desc"
            @leads = @leads.order("#{params['key']} #{params['sort']} NULLS LAST")
          else
            @leads = @leads.order("#{params['key']} #{params['sort']} NULLS FIRST")
          end
        else
          @leads = @leads.order("leads.ncd asc NULLS FIRST, leads.created_at DESC")
        end
        total_leads = @leads.count
        leads = @leads.includes(:status,:source).paginate(:page => params[:page], :per_page => PER_PAGE).as_api_response(:details)
        render json: {leads: leads, count: total_leads, per_page: PER_PAGE}, status: 200 and return
      end

      def show
        render json: { status: true, lead: @lead.as_api_response(:meta_details_with_detail) }, status: 200 and return
      end

      def create
        lead = @leads.new
        lead.assign_attributes(lead_params)
        lead.user_id = @current_app_user.id if lead.user_id.blank?
        if lead.save
          render json: {status: true, message: "Success"}, status: 201 and return
        else
          render json: {status: false, message: lead.errors.full_messages.join(', ')}, status: 422 and return
        end

      end

      def settings
        if current_user.company.can_assign_all_users
          users = current_user.company.users
        else
          users = current_user.manageables
        end
        users = users.as_json(only: [:id, :name])
        if current_user.company.managerwise_closing_executive_active
          if current_user.is_executive?
            closing_executives = current_user.company.users.managers_role.meeting_executives.select("users.id, users.name").as_json
          else
            closing_executives = current_user.manageables.meeting_executives.select("users.id, users.name").as_json
          end
        else
          closing_executives = current_user.manageables.meeting_executives.select("users.id, users.name").as_json
        end
        projects = current_user.company.projects.as_json(only: [:id, :name])
        bank_names = ::Leads::Visit::BANK_NAMES.as_json
        render json: {users: users, projects: projects, bank_names: bank_names, closing_executives: closing_executives}, status: 200 and return
      end

      def histories
        lead_logs = @lead.custom_audits.order(created_at: :desc)
        render json: {audits: lead_logs.as_api_response(:public)}, status: 200 and return
      end

      def magic_fields
        @company = @current_app_user.company
        magic_fields = @company.magic_fields
        render json: { status: true, magic_fields:  magic_fields}, status: 200 and return
      end

      def delete_visit
        visit = @lead.visits.find_by_id(params[:visit_id])
        if visit.destroy
          render json: {message: "Success"}, status: 200 and return
        else
          render json: {message: visit.errors.full_messages.join(', ')}, status: 200 and return
        end
      end

      def update
        if @lead.update_attributes(lead_params)
          render json: {lead: @lead.reload.as_api_response(:meta_details_with_detail)}, status: 200 and return
        else
          render json: {status: false, message: @lead.errors.full_messages.join(",")}, status: 400 and return
        end
      end

      def make_call
        if @lead.make_call(@current_app_user)
          render json: {success: true}, status: 200
        else
          render json: {success: false}, status: 200
        end
      end

      def create_call_attempt
        @lead.call_attempts.create(user_id: @current_app_user.id)
      end

      def log_call_attempt
        call_attempt = @lead.call_attempts.build(user_id: @current_app_user.id)
        if call_attempt.save
          render json: {status: true, message: "Success"}, status: 201 and return
        else
          render json: {status: false, message: call_attempt.errors.full_messages.join(', ')}, status: 422 and return
        end
      end

      private

      def find_accessible_leads
        @leads = ::Lead.search_base_leads(@current_app_user)
        Lead.current_user = @current_app_user
      end

      def find_lead
        @lead = @leads.find_by_uuid params[:uuid]
        render json: {message: "Cannot find lead", error: "Invalid UUID Sent"}, status: 422 and return if @lead.blank?
      end

      def lead_params
        magic_fields = (@current_app_user.company.magic_fields.map{|field| field.name.to_sym} rescue [])
        params.require(:lead).permit(
          *magic_fields,
          :name,
          :email,
          :mobile,
          :other_phones,
          :project_id,
          :source_id,
          :ncd,
          :user_id,
          :closing_executive,
          :comment,
          :status_id,
          :presale_stage_id,
          :dead_reason_id,
          :tentative_visit_planned,
          :broker_id, :booking_date, :booking_form, :token_date,
          :enquiry_sub_source_id, :lease_expiry_date,
          :visits_attributes=>[:id, :date, :is_visit_executed, :is_postponed, :is_canceled, :comment, :location, :site_visit_form, :surronding, :finalization_period, :loan_sanctioned, :bank_name, :loan_amount, :eligibility, :own_contribution_minimum, :own_contribution_maximum, :loan_requirements]
        )
      end

      def current_user
        @current_app_user
      end

      def search_params
        params.permit(:as, :bs, :comment, :created_at_from, :created_at_upto, :email, :lead_no, :name, :ncd_from, :ncd_upto, :mobile, :visited_date_from, :visited_date_upto, :booking_date_to, :booking_date_from, :token_date_from, :token_date_to, :other_phones, :todays_call_only, :backlogs_only, :manager_id, :expired_from, :expired_upto, :lead_statuses=>[], :project_ids=>[], :assigned_to=>[], closing_executive: [], stage_ids: [], :source_ids=>[], country_ids: [], dead_reasons: [])
      end
    end
  end
end
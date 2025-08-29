module Api
  class MobileCrmController < ::ApiController
    def dashboard
      leads = ::Lead.user_leads(@current_app_user)
      todays_call = leads.todays_calls.count
      backlogs = leads.backlogs_for(@current_app_user.company).count
      expired_lease_count = @current_app_user.company.is_allowed_field?("lease_expiry_date") ? (leads.expired.size) : 0
      expiring_lease_count = @current_app_user.company.is_allowed_field?("lease_expiry_date") ? (leads.expiring.size) : 0
      render json: {todays_call: todays_call, backlogs: backlogs, expired_lease_count: expired_lease_count, expiring_lease_count: expiring_lease_count}, status: 200 and return
    end

    def settings
      company = @current_app_user.company
      sources = company.sources.reorder(nil).order(:name).select("sources.id, sources.name").as_json
      statuses = company.statuses.select("DISTINCT statuses.id, statuses.name").as_json
      dead_status_ids = company.dead_status_ids
      token_status_ids = company.token_status_ids
      bookings_done_ids = [company.booking_done_id]
      site_visit_planned_ids = [company.expected_site_visit&.id]
      dead_reasons = company.reasons.active
      sub_sources=company.sub_sources.as_json(only: [:id, :name])
      required_fields = company.required_fields.as_json
      cp_sources_ids = company.cp_source_ids
      channel_partners = company.brokers.select("brokers.id, brokers.name").as_json
      countries = Country.select("id, name").as_json
      render json: {sources: sources, statuses: statuses, dead_status_ids: dead_status_ids, bookings_done_ids: bookings_done_ids, dead_reasons: dead_reasons, site_visit_planned_ids: site_visit_planned_ids, token_status_ids: token_status_ids,  sub_source: sub_sources, required_fields: required_fields, cp_sources_ids: cp_sources_ids, channel_partners: channel_partners, countries: countries}, status: 200 and return
    end

    def status_wise_stage
      stages = @current_app_user.company.status_wise_stage_data
      render json: {stages: stages}, status: 200 and return
    end

    def suggest_users
      render json: {status: false, message: "Please enter search string"}, status: 400 and return if (params[:input_str].blank? || params[:input_str].length < 3)
      if @current_app_user.company.can_assign_all_users
        users = @current_app_user.company.users.active
      else
        users = @current_app_user.manageables.active
      end
      users = users.where("users.name ILIKE ?", "#{params[:input_str].downcase}%").select("users.id, users.name").as_json
      render json: {users: users}, status: 200 and return
    end

    def suggest_managers
      render json: {status: false, message: "Please enter search string"}, status: 400 and return if (params[:input_str].blank? || params[:input_str].length < 3)
      managers = @current_app_user.manageables.active.managers.where("users.name ILIKE ?", "#{params[:input_str].downcase}%").select("users.id, users.name").as_json
      render json: {managers: managers}, status: 200 and return
    end

    def suggest_projects
      render json: {status: false, message: "Please enter search string"}, status: 400 and return if (params[:input_str].blank? || params[:input_str].length < 3)
      projects = @current_app_user.company.projects.where("projects.name ILIKE ?", "#{params[:input_str].downcase}%").select("projects.id, projects.name").as_json
      render json: {projects: projects}, status: 200 and return
    end
  end
end
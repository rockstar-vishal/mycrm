class ReportsController < ApplicationController

  before_action :set_company_props
  before_action :set_start_end_date
  before_action :set_base_leads, except: [:campaigns, :campaign_detail, :activity, :activity_details, :visits, :trends, :site_visit_planned, :scheduled_site_visits, :scheduled_site_visits_detail, :presale_visits]
  helper_method :ld_path, :bl_path, :dld_path, :ad_path, :comment_edit_text, :status_edit_html, :vd_path

  def source
    data = @leads.group("source_id, status_id").select("COUNT(*), source_id, status_id, json_agg(id) as lead_ids")
    @statuses = @statuses.where(:id=>data.map(&:status_id).uniq)
    @sources = @sources.where(:id=>data.map(&:source_id).uniq)
    @data = data.as_json(except: [:id])
    respond_to do |format|
      format.html
      format.csv do
        send_data @leads.source_report_to_csv({}, current_user), filename: "source_wise_report_#{Date.today.to_s}.csv"
      end
    end
  end

  def trends
    render json: {message: "You are not allowed to access this"}, status: 403 unless (current_user.is_super? || current_user.is_sl_admin?)
    dates_range = (@start_date.to_date..@end_date.to_date).to_a
    @leads = @leads.filter_leads_for_reports(params, current_user)
    @lead_gen = @leads.where(:created_at=>@start_date..@end_date).group("date(created_at)").select("COUNT(*), date(created_at) as created_date").as_json(except: [:id])
    dates_range.map{|k| @lead_gen.select{|a| a['created_date'] == k}.present? ? true : @lead_gen << {"created_date"=>k, "count"=>0}}
    @conversions = @leads.where(:conversion_date=>@start_date.to_date..@end_date.to_date).booked_for(current_user.company).group("conversion_date").select("conversion_date, COUNT(*)").as_json(except: [:id])
    dates_range.map{|k| @conversions.select{|a| a['conversion_date'] == k}.present? ? true : @conversions << {"conversion_date"=>k, "count"=>0}}
    @visits = @leads.joins{visits}.where("leads_visits.date BETWEEN ? AND ?", @start_date.to_date, @end_date.to_date).group("leads_visits.date").select("COUNT(*), leads_visits.date as visit_date").as_json(except: [:id])
    dates_range.map{|k| @visits.select{|a| a['visit_date'] == k}.present? ? true : @visits << {"visit_date"=>k, "count"=>0}}
  end

  def projects
    data = @leads.group("project_id, status_id").select("COUNT(*), project_id, status_id, json_agg(id) as lead_ids")
    uniq_projects = @leads.map{|k| k[:project_id]}.uniq
    uniq_statuses = @leads.map{|k| k[:status_id]}.uniq
    @projects = @projects.where(:id=>uniq_projects)
    @statuses = @statuses.where(:id=>uniq_statuses)
    @data = data.as_json(except: [:id])
    respond_to do |format|
      format.html
      format.csv do
        send_data @leads.project_report_to_csv({}, current_user), filename: "project_wise_report_#{Date.today.to_s}.csv"
      end
    end
  end

  def call_report
    @data = Leads::CallLog.includes(:user).where("user_id IN (?) AND created_at BETWEEN ? AND ?", current_user.manageables.ids, @start_date, @end_date)
    if params[:is_advanced_search].present?
      @data = @data.advance_search(call_log_report_params)
    end
    @users = current_user.manageables.where(id: @data.map(&:user_id))
  end

  def visits
    if current_user.company.enable_advance_visits
      @leads = @leads.joins{visits}.where("leads_visits.is_visit_executed = ? AND leads_visits.date BETWEEN ? AND ?", true, @start_date.to_date, @end_date.to_date)
    else
      @leads = @leads.joins{visits}.where("leads_visits.date BETWEEN ? AND ?", @start_date.to_date, @end_date.to_date)
    end
    @users = current_user.manageables.where(:id=>@leads.map(&:user_id))
    @statuses = @statuses.where(:id=>@leads.map(&:status_id))
    if params[:is_advanced_search].present?
      @leads = @leads.advance_search(visit_params, current_user)
    end
    respond_to do |format|
      format.html
      format.csv do
        send_data @leads.visits_to_csv({}, current_user, @start_date, @end_date), filename: "visits_report_#{Date.today.to_s}.csv"
      end
    end
  end

  def presale_visits
    @leads = @leads.joins{visits}.where("leads_visits.date BETWEEN ? AND ?", @start_date.to_date, @end_date.to_date)
    @presale_users = current_user.manageables.where(:id=>@leads.map(&:presale_user_id))
    @statuses = @statuses.where(:id=>@leads.map(&:status_id))
  end

  def campaigns
    @leads = @leads.where(:user_id=>current_user.manageable_ids)
    @campaigns = current_user.company.campaigns
    respond_to do |format|
      format.html
      format.csv do
        send_data @leads.campaign_report_to_csv({}, current_user), filename: "campaign_report_#{Date.today.to_s}.csv"
      end
    end
  end

  def campaign_detail
    @campaign = current_user.company.campaigns.find_by(uuid: params[:campaign_uuid])
    @leads = @leads.where(:user_id=>current_user.manageable_ids)
    @campaign_leads = @leads.where(created_at: @campaign.start_date.beginning_of_day..@campaign.end_date.end_of_day, source_id: @campaign.source_id)
    @campaign_visited_leads = @campaign_leads.joins{visits}.uniq
    @campaign_date_range = @campaign_leads.order(created_at: :desc).pluck(:created_at).map(&:to_date).uniq
  end

  def backlog
    company = current_user.company
    @leads = @leads.backlogs_for(company)
    data = @leads.group("user_id, status_id").select("COUNT(*), user_id, status_id, json_agg(leads.id) as lead_ids")
    @statuses = @statuses.where(:id=>data.map(&:status_id).uniq)
    @users = current_user.manageables.where(:id=>data.map(&:user_id).uniq)
    @data = data.as_json
    respond_to do |format|
      format.html
      format.csv do
        send_data @leads.backlog_report_to_csv({}, current_user), filename: "back_logs_report_#{Date.today.to_s}.csv"
      end
    end
  end

  def dead
    @data = @leads.where(:status_id=>current_user.company.dead_status_ids)
    @reasons = current_user.company.reasons.where(:id=>@data.map(&:dead_reason_id).uniq)
    @users = current_user.manageables.where(:id=>@data.map(&:user_id).uniq)
    respond_to do |format|
      format.html
      format.csv do
        send_data @leads.dead_report_to_csv({}, current_user), filename: "dead_lead_report_#{Date.today.to_s}.csv"
      end
    end
  end

  def leads
    data = @leads.group("user_id, status_id").select("COUNT(*), user_id, status_id, json_agg(leads.id) as lead_ids")
    @statuses = @statuses.where(:id=>data.map(&:status_id).uniq)
    @users = current_user.manageables.where(:id=>data.map(&:user_id).uniq)
    @data = data.as_json
    respond_to do |format|
      format.html
      format.csv do
        send_data @leads.report_to_csv({}, current_user), filename: "lead_user_wise_report_#{Date.today.to_s}.csv"
      end
    end
  end

  def scheduled_site_visits
    @start_date = params[:start].present? ? Time.zone.parse(params[:start]).beginning_of_day : (Time.zone.now).beginning_of_day
    @end_date = params[:end].present? ? Time.zone.parse(params[:end]).end_of_day : (Time.zone.now + start_offset.day).end_of_day
    @leads = @leads.site_visit_planned_leads(current_user).where("leads.tentative_visit_planned BETWEEN ? AND ?", @start_date.to_date, @end_date.to_date)
    render json: @leads.as_api_response(:event)
  end

  def scheduled_site_visits_detail
    @default_tab = 'leads-detail'
    @lead = @leads.find_by(id: params[:lead_id])
    @company = current_user.company
    render_modal('leads/show', {:class=>'right'})
  end

  def user_call_reponse_report
    data = current_user.company.call_attempts.where.not(response_time: nil).where(user_id: current_user.manageable_ids)
    data = data.where(created_at: @start_date..@end_date)
    if params[:is_advanced_search].present?
      data = data.advance_search(user_call_reponse_search)
    end
    data = data.group("call_attempts.user_id").select("COUNT(*) as count, call_attempts.user_id as user_id, sum(response_time) as response_time, json_agg(call_attempts.id) as call_attempts_ids, json_agg(call_attempts.lead_id) as lead_ids")
    @users = current_user.manageables.where(:id=>data.map(&:user_id).uniq)
    @data = data.as_json
  end

  def site_visit_planned_tracker
    @data = @leads.site_visit_scheduled
    @users = current_user.manageables.where(:id=>@data.map(&:user_id).uniq)
  end

  def site_visit_planned
    if current_user.company.setting.present? && current_user.company.set_svp_default_7_days
      start_offset= 7
    else
      start_offset = 60
    end
    @start_date = params[:start_date].present? ? Time.zone.parse(params[:start_date]).beginning_of_day : (Time.zone.now).beginning_of_day
    @end_date = params[:end_date].present? ? Time.zone.parse(params[:end_date]).end_of_day : (Time.zone.now + start_offset.day).end_of_day
    @leads = @leads.site_visit_planned_leads(current_user).where("leads.tentative_visit_planned BETWEEN ? AND ?", @start_date.to_date, @end_date.to_date)
    if params[:project_ids].present? || params[:manager_id].present?
      @leads=@leads.filter_leads_for_reports(params, current_user)
    end
    if params["visited"].present? && params["visited"] == "true"
      @leads = @leads.joins{visits}
    end
    @leads_count = @leads.size
    if params["key"].present? && params["sort"].present?
      @leads = @leads.order("#{params['key']} #{params['sort']} NULLS FIRST")
    else
      @leads = @leads.order("leads.tentative_visit_planned asc NULLS FIRST, leads.created_at DESC")
    end
    if params[:calender_view].present?
      @leads = @leads
      render 'site_visit_planned_calender_view'
    else
      respond_to do |format|
        format.html do
          @leads = @leads.includes{visits}.order("leads.tentative_visit_planned ASC").paginate(:page => params[:page], :per_page => 50)
        end
        format.csv do
          if @leads_count <= 4000
            send_data @leads.to_csv({}, current_user, request.remote_ip, @leads.count), filename: "Site_visit_planned_#{Date.today.to_s}.csv"
          else
            render json: {message: "Export of more than 4000 leads is not allowed in one single attempt. Please contact management for more details"}, status: 403
          end
        end
      end
    end
  end

  def activity
    activities = current_user.company.associated_audits.where(:created_at=>@start_date..@end_date)
    unless current_user.is_super?
      activities = activities.where(:user_id=>current_user.manageable_ids, :user_type=>"User")
    end
    lead_ids = activities.pluck(:auditable_id)
    leads = current_user.manageable_leads.where(:id=>lead_ids.uniq)
    leads = leads.filter_leads_for_reports(activity_search_params, current_user)
    activities = activities.where(:auditable_id=>leads.ids.uniq)
    @unique_activities = activities.select("DISTINCT ON (audits.auditable_id) audits.* ")
    @status_edits = activities.where("audits.audited_changes ->> 'status_id' != ''").group("user_id").select("user_id, json_agg(audited_changes) as change_list")
    @comment_edits = activities.where("audits.audited_changes ->> 'comment' != ''").group("user_id").select("user_id, json_agg(audited_changes) as change_list")
    @users = current_user.manageables.where(:id=>(@status_edits.map(&:user_id).uniq | @comment_edits.map(&:user_id).uniq))
    @status_edits = @status_edits.as_json
    @comment_edits = @comment_edits.as_json
    respond_to do |format|
      format.html
      format.csv do
        send_data @leads.activity_to_csv({}, current_user, @start_date, @end_date), filename: "activities_report_#{Date.today.to_s}.csv"
      end
    end
  end

  def activity_details
    @user = current_user.manageables.find(params[:user_id])
    @activities = current_user.company.associated_audits.where(:created_at=>@start_date..@end_date, :user_id=>@user.id, :user_type=>"User").order(auditable_id: :asc)
    @statuses_list = @current_user.company.statuses.select("statuses.id, statuses.name").as_json
  end

  def closing_executives
    data = @leads.where.not(closing_executive: nil).group("closing_executive, status_id").select("COUNT(*), closing_executive, status_id, json_agg(leads.id) as lead_ids")
    @statuses = current_user.company.statuses.where(:id=>data.map(&:status_id).uniq)
    @users = current_user.manageables.where(:id=>data.map(&:closing_executive).uniq)
    @data = data.as_json
    puts @data
    respond_to do |format|
      format.html
      format.csv do
        send_data @leads.closing_executive_to_csv({}, current_user), filename: "lead_closinguser_wise_report_#{Date.today.to_s}.csv"
      end
    end
  end

  def site_visit_userwise
    @data = @leads.joins{visits}.where("leads_visits.date BETWEEN ? AND ?", @start_date.to_date, @end_date.to_date).group("leads_visits.user_id").select("COUNT(*),leads_visits.user_id, json_agg(leads_visits.id) as visit_count, json_agg(leads.id) as lead_ids").as_json
    @data = @data.select{|data| data["user_id"].present?}
    @users = current_user.manageables.calling_executives.where(id: @data.collect{|d| d["user_id"]})
    @statuses = @statuses.where(:id=>@data.collect{|d| d["status_id"]})
  end

  def ld_path q_params
    return leads_path(is_advanced_search: true, created_at_from: @start_date.to_date, created_at_upto: @end_date.to_date, :updated_at_from=>params[:updated_from], :updated_at_upto=>params[:updated_upto], :project_ids=>params[:project_ids], :source_id=>params[:source_ids], :manager_id=>params[:manager_id], :assigned_to=>params[:user_ids], :customer_type=>params[:customer_type], site_visit_done: params[:site_visit_done], site_visit_planned: params[:site_visit_planned], site_visit_cancel: params[:site_visit_cancel], revisit: params[:revisit], booked_leads: params[:booked_leads], token_leads: params[:token_leads], postponed: params[:postponed], visit_cancel: params[:visit_cancel], site_visit_from: params[:site_visit_from], site_visit_upto: params[:site_visit_upto], booking_date_from: params[:booking_date_from], booking_date_to: params[:booking_date_to], **q_params)
  end

  def bl_path q_params
    return leads_path(is_advanced_search: true, created_at_from: @start_date.to_date, created_at_upto: @end_date.to_date, :updated_at_from=>params[:updated_from], :updated_at_upto=>params[:updated_upto], :project_ids=>params[:project_ids], :source_id=>params[:source_ids], :manager_id=>params[:manager_id], :assigned_to=>params[:user_ids], :backlogs_only=>true, customer_type: params[:customer_type], **q_params)
  end

  def dld_path q_params
    return leads_path(is_advanced_search: true, created_at_from: @start_date.to_date, created_at_upto: @end_date.to_date, :updated_at_from=>params[:updated_from], :updated_at_upto=>params[:updated_upto], :project_ids=>params[:project_ids], :source_id=>params[:source_ids], :manager_id=>params[:manager_id], :assigned_to=>params[:user_ids], customer_type: params[:customer_type], :lead_statuses=>current_user.company.dead_status_ids, **q_params)
  end

  def ad_path q_params
    return reports_activity_details_path(start_date: @start_date.to_date, end_date: @end_date.to_date, :project_ids=>params[:project_ids], :source_id=>params[:source_ids], :manager_id=>params[:manager_id], customer_type: params[:customer_type], **q_params)
  end

  def vd_path q_params
    return leads_path(is_advanced_search: true, visited_date_from: @start_date.to_date, visited_date_upto: @end_date.to_date, :updated_at_from=>params[:updated_from], :updated_at_upto=>params[:updated_upto], :project_ids=>params[:project_ids], :source_id=>params[:source_ids], :manager_id=>params[:manager_id], :assigned_to=>params[:user_ids], :lead_ids=>params[:lead_ids], :visit_counts=>params[:visit_counts], customer_type: params[:customer_type], presale_user_id: params[:presale_user_id], sv_user: params[:sv_user], **q_params)
  end

  def status_edit_html change_entry
    return "No Change" if change_entry.blank?
    if change_entry.kind_of?(Array)
      return "#{(@statuses_list.detect{|k| k['id'] == change_entry.first}['name'] rescue '')} <svg width='1em' height='1em' viewBox='0 0 16 16' class='bi bi-arrow-right' fill='currentColor' xmlns='http://www.w3.org/2000/svg'>
  <path fill-rule='evenodd' d='M10.146 4.646a.5.5 0 0 1 .708 0l3 3a.5.5 0 0 1 0 .708l-3 3a.5.5 0 0 1-.708-.708L12.793 8l-2.647-2.646a.5.5 0 0 1 0-.708z'/>
  <path fill-rule='evenodd' d='M2 8a.5.5 0 0 1 .5-.5H13a.5.5 0 0 1 0 1H2.5A.5.5 0 0 1 2 8z'/>
</svg> #{(@statuses_list.detect{|k| k['id'] == change_entry.last}['name'] rescue '')}"
    else
      return "Created with Status <b>#{(@statuses_list.detect{|k| k['id'] == change_entry}['name'] rescue '')}</b>"
    end
  end

  def comment_edit_text change_entry
    return "No Change" if change_entry.blank?
    if change_entry.kind_of?(Array)
      diff = change_entry.last.to_s.sub(change_entry.first.to_s, "").strip
      return "(Added) #{diff}"
    else
      return "(Added) #{change_entry}"
    end
  end

  private
  def set_start_end_date
    start_offset = 7
    @start_date = params[:start_date].present? ? Time.zone.parse(params[:start_date]).beginning_of_day : (Time.zone.now - start_offset.day).beginning_of_day
    @end_date = params[:end_date].present? ? Time.zone.parse(params[:end_date]).end_of_day : Time.zone.now.end_of_day
  end

  def set_company_props
    company = current_user.company
    @leads = company.leads
    @statuses = company.statuses
    @sources = company.sources
    @projects = company.projects
  end

  def activity_search_params
    params.permit(:customer_type, :manager_id, :source_ids=>[], :project_ids=>[])
  end

  def visit_params
    params.permit(:customer_type, :visit_counts, :manager_id, :project_ids=>[], :source_ids=>[], :presale_user_id=>[])
  end

  def site_visit_tracker_params
    params.permit(:revisit, :site_visit_planned, :site_visit_done, :site_visit_cancel, :booked_leads, :customer_type, :site_visit_from, :site_visit_upto, :token_leads, :visit_cancel, :postponed)
  end

  def set_base_leads
    @leads = @leads.where(:created_at=>@start_date..@end_date)
    unless current_user.is_super?
      @leads = @leads.where("user_id IN (:user_ids) or closing_executive IN (:user_ids)", :user_ids=> current_user.manageable_ids)
    end
    @leads = @leads.filter_leads_for_reports(params, current_user)
  end

  def call_log_report_params
    params.permit(:call_direction, :start_date, :end_date, :todays_calls, :completed, :abandoned_calls, :missed_calls)
  end

  def user_call_reponse_search
    params.permit(
      :start_date,
      :end_date,
      project_ids: []
    )
  end

end

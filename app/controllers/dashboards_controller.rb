class DashboardsController < ApplicationController

  before_action :set_start_end_date, on: :statistics
  before_action :set_base_leads, on: [:statistics, :lease_data]
  before_action :trends_report, :marketing_campaigns_report, :leads_report, :source, :projects, on: :statistics

  def index
    if current_user.is_sysad?
      redirect_to companies_path
    else
      redirect_to statistics_dashboards_path
    end
  end

  def statistics
  end

  def trends_report
    start_offset = 7
    dates_range = (@start_date.to_date..@end_date.to_date).to_a
    @lead_gen = @leads.where(:created_at=>@start_date..@end_date).group("date(created_at)").select("COUNT(*), date(created_at) as created_date").as_json(except: [:id])
    dates_range.map{|k| @lead_gen.select{|a| a['created_date'] == k}.present? ? true : @lead_gen << {"created_date"=>k, "count"=>0}}
    @conversions = @leads.where(:conversion_date=>@start_date.to_date..@end_date.to_date).booked_for(current_user.company).group("conversion_date").select("conversion_date, COUNT(*)").as_json(except: [:id])
    dates_range.map{|k| @conversions.select{|a| a['conversion_date'] == k}.present? ? true : @conversions << {"conversion_date"=>k, "count"=>0}}
    @visits = @leads.joins{visits}.where("leads_visits.date BETWEEN ? AND ?", @start_date.to_date, @end_date.to_date).group("leads_visits.date").select("COUNT(*), leads_visits.date as visit_date").as_json(except: [:id])
    dates_range.map{|k| @visits.select{|a| a['visit_date'] == k}.present? ? true : @visits << {"visit_date"=>k, "count"=>0}}
  end

  def lease_data
    leads = @leads.where.not(lease_expiry_date: nil)
    expiring_lease_chart = leads.find_by_sql("
      select
        COUNT(*), lease_expiry_date
      from
        leads
      where (leads.lease_expiry_date BETWEEN '#{Date.today.to_s}' AND '#{(Date.today+1.month).to_s}')
      group by lease_expiry_date
    ")
    expired_lease_leads_chart = @leads.find_by_sql("
      select
        COUNT(*), lease_expiry_date
      from
        leads
      where (lease_expiry_date BETWEEN '#{(Date.today-1.month).to_s}' AND '#{(Date.today-1.day).to_s}')
      group by lease_expiry_date
    ")
    respond_to do |format|
      format.json do
        render json: {expiring_lease_chart: expiring_lease_chart, expired_lease_chart: expired_lease_leads_chart, status: 200}
      end
    end
  end

  def marketing_campaigns_report
    @campaigns = current_user.company.campaigns
  end

  def leads_report
    data = @leads.group("user_id, status_id").select("COUNT(*), user_id, status_id, json_agg(id) as lead_ids")
    @statuses = @company.statuses
    @sources = @company.sources
    @statuses = @statuses.where(:id=>data.map(&:status_id).uniq)
    @users = current_user.manageables.where(:id=>data.map(&:user_id).uniq)
    @user_data = data.as_json
  end

  def projects
    data = @leads.group("project_id, status_id").select("COUNT(*), project_id, status_id, json_agg(id) as lead_ids")
    uniq_projects = @leads.map{|k| k[:project_id]}.uniq
    uniq_statuses = @leads.map{|k| k[:status_id]}.uniq
    @projects = @company.projects
    @projects = @projects.where(:id=>uniq_projects)
    @statuses = @company.statuses.where(:id=>uniq_statuses)
    @project_data = data.as_json(except: [:id])
  end

  def source
    data = @leads.group("source_id, status_id").select("COUNT(*), source_id, status_id, json_agg(id) as lead_ids")
    @statuses = @statuses.where(:id=>data.map(&:status_id).uniq)
    @sources = @sources.where(:id=>data.map(&:source_id).uniq)
    @data = data.as_json(except: [:id])
  end

  private

  def set_start_end_date
    start_offset = 30
    @start_date = (Time.zone.now - start_offset.day).beginning_of_day
    @end_date = Time.zone.now.end_of_day
  end

  def set_base_leads
    @company = current_user.company
    @leads = @company.leads
    @leads = @leads.where(:created_at=>@start_date..@end_date)
    unless current_user.is_super?
      @leads = @leads.where(:user_id=>current_user.manageable_ids)
    end
  end

end
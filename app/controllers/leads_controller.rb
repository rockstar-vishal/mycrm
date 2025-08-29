class LeadsController < ApplicationController
  before_action :set_leads
  before_action :set_lead, only: [:show, :delete_visit, :make_call,:new_visit, :create_visit, :edit, :update, :destroy, :histories, :edit_visit, :new_loan, :create_loan, :copy, :perform_copy]

  respond_to :html
  PER_PAGE = 20

  def index
    @users = current_user.manageables
    if params[:is_advanced_search].present? || params[:search_query].present?
      if @company.remove_closed?
        if params[:lead_statuses].present?
          @leads = @leads.search_base_leads(current_user)
        else
          @leads = @leads.user_leads(current_user)
        end
      else
        @leads = @leads.search_base_leads(current_user)
      end
    else
      @leads = @leads.user_leads(current_user)
    end
    if params[:is_advanced_search].present? && params[:search_query].blank?
      if params["save_search_id"].present?
        @leads = @leads.advance_search(current_user.search_histories.find(params[:save_search_id]).search_params, current_user)
      else
        @leads = @leads.advance_search(search_params, current_user)
        if params["search_name"].present? && params["set_search"].present?
          @search_history = @leads.save_search_history(search_params, current_user, params["search_name"])
        end
      end
    end

    if params[:search_query].present?
      @leads = @leads.basic_search(params[:search_query], current_user)
    end
    if params[:showable_ids_cs].present?
      @leads = @leads.where(:id=>params[:showable_ids_cs].split(",").uniq)
    end
    if params["key"].present? && params["sort"].present?
      if params["key"] == 'project_id'
        @leads = @leads.includes{project}.order("projects.name #{params['sort']} NULLS FIRST")
      elsif params["key"] == 'status_id'
        @leads = @leads.includes{status}.order("statuses.name #{params['sort']} NULLS FIRST")
      else
        if @company.setting.present? && @company.enable_ncd_sort_nulls_last && params['sort'] == "desc"
          @leads = @leads.order("#{params['key']} #{params['sort']} NULLS LAST")
        else
          @leads = @leads.order("#{params['key']} #{params['sort']} NULLS FIRST")
        end
      end
    else
      @leads = @leads.order("leads.ncd asc NULLS FIRST, leads.created_at DESC")
    end
    # @leads = @leads.includes{status}.includes{property_type}.includes{transaction_type}.includes{user}.includes{project}.includes{enquiry_source}.includes{outlet_location}
    @leads_count = @leads.size
    respond_to do |format|
      format.html do
        @leads = @leads.includes{visits}.paginate(:page => params[:page], :per_page => PER_PAGE)
      end
      format.csv do
        if @leads_count <= 4000
          send_data @leads.to_csv({}, current_user, request.remote_ip, @leads.count), filename: "leads_#{Date.today.to_s}.csv"
        else
          render json: {message: "Export of more than 4000 leads is not allowed in one single attempt. Please contact management for more details"}, status: 403
        end
      end
    end
  end

  def calender_view
    start_offset = 60
    respond_to do |format|
      format.html
      format.json do
        @leads = @leads.user_leads(current_user)
        @start_date = params[:start].present? ? Time.zone.parse(params[:start]).beginning_of_day : (Time.zone.now).beginning_of_day
        @end_date = params[:end].present? ? Time.zone.parse(params[:end]).end_of_day : (Time.zone.now + start_offset.day).end_of_day
        @leads = @leads.where("leads.ncd BETWEEN ? AND ?", @start_date.to_date, @end_date.to_date)
        render json: @leads.as_api_response(:lead_event)
      end
    end
  end

  def bulk_action
    @leads = @leads.where(id: params[:lead_ids])
    should_recycle = params[:should_recycle] == "true"
    if params["button"] == "send_email_to_team"
      send_lead_details
    elsif params["button"] == "delete"
      @leads.each do |l|
        l.destroy
      end
      flash[:danger] = "Selected leads deleted"
    elsif params["button"] == 'bulk_call'
      @leads.initiate_bulk_call(current_user)
      flash[:notice] = 'Selected Leads Call Initiated'
    else
      @leads.each do |lead|
        lead.user_id = params["assigned_to"].present? ? params["assigned_to"] : lead.user_id
        lead.status_id = params["lead_status"].present? ? params["lead_status"] : lead.status_id
        if should_recycle
          lead.ncd = params["ncd"].present? ? Time.zone.parse(params["ncd"]) : nil
          lead.reset_comment
        else
          lead.ncd = params["ncd"].present? ? Time.zone.parse(params["ncd"]) : lead.ncd
        end
        lead.project_id = params["project_id"].present? ? params["project_id"] : lead.project_id
        lead.save
      end
      flash[:success] = "Selected leads are updated."
    end
    redirect_to request.referer
  end

  def send_lead_details
    email_lists = current_user.manageables.where(id: params[:email_to]).pluck(:email)
    mail_params = {subject: params[:subject], message: params[:message]}
    if email_lists.present?
      if mail_params[:subject].blank?
        flash[:danger] = "Please add subject for sending the email!"
      else
        UserMailer.share_lead_details_on_email(current_user, email_lists, @leads, mail_params).deliver!
        flash[:notice] = "Email sent Successfully!"
      end
    else
      flash[:success] = "Please select email from the email lists!"
    end
  end


  def show
    @default_tab = 'leads-detail'
    render_modal('show', {:class=>'right'})
  end

  def new_loan
    @loan = @lead.build_loan
    respond_to do |format|
      format.js do
        render_modal('loan')
      end
      format.html
    end
  end

  def create_loan
    @loan = @lead.build_loan(loan_params.merge(company_id: @lead.company_id, status_id: ::Loan::DEFAULT_STATUS))
    is_save = @loan.save
    @lead.errors.add(:base, @loan.errors.full_messages) unless is_save
    respond_to do |format|
      format.js do
        if is_save
          flash[:notice] = "Loan Created Successfully"
          xhr_redirect_to redirect_to: request.referer
        else
          render_modal 'loan'
        end
      end
      format.html do
        if is_save
          flash[:notice] = "Loan Created Successfully"
          redirect_to leads_path
        else

          render 'loan'
        end
      end
    end
  end

  def new_visit
    @visits = @lead.visits.build
    render_modal('site_visit_form')
  end

  def create_visit
    @default_tab = 'site-visit-detail'
    if @lead.update_attributes(lead_params)
      flash[:notice] = 'Visit Detail Updated Successfully'
      render_modal('show', {:class=>'right'})
    else
      render_modal('site_visit_form')
    end
  end

  def delete_visit
    @default_tab = "site-visit-detail"
    @visit = @lead.visits.find(params[:visit_id])
    if @visit.destroy
      flash[:notice] = "Visit Deleted Successfully"
    else
      flash[:alert] = "Error!"
    end
    render_modal('show', {:class=>'right'})
  end

  def new
    @lead = @leads.new
    if params[:lead_id].present?
      lead = @leads.find(params[:lead_id])
      @lead.assign_attributes(
        name: lead.name,
        email: lead.email,
        mobile: lead.mobile,
        status_id: lead.status_id,
        city_id: lead.city_id,
        locality_id: lead.locality_id)
    end
  end

  def edit
    respond_to do |format|
      format.js do
        render_modal('edit')
      end
      format.html
    end
  end

  def copy
    respond_to do |format|
      format.js do
        render_modal('copy')
      end
      format.html
    end
  end

  def create
    @lead = @leads.new
    @lead.assign_attributes(lead_params)
    unless @lead.company.round_robin_enabled?
      @lead.user_id = current_user.id if @lead.user_id.blank?
    end
    if @lead.save
      flash[:notice] = "Lead Created Successfully"
      redirect_to leads_path and return
    else
      render 'new'
    end
  end

  def perform_copy
    user_id = params[:user_id]
    project_id = params[:project_id]
    lead = @company.leads.build(user_id: user_id, project_id: params[:project_id], status_id: (@company.new_status_id rescue nil), name: @lead.name, mobile: @lead.mobile, source_id: ::Lead::CROSS_PITCH_SOURCE_ID,
email: @lead.email, other_phones: @lead.other_phones, other_emails: @lead.other_emails)
    is_save = lead.save
    respond_to do |format|
      format.js do
        if is_save
          flash[:notice] = "Cross Pitch Lead Created Successfully"
          xhr_redirect_to redirect_to: request.referer
        else
          render_modal 'copy'
        end
      end
      format.html do
        if is_save
          flash[:notice] = "Lead Updated Successfully"
          redirect_to leads_path
        else
          render 'copy'
        end
      end
    end
  end

  def update
    is_save = @lead.update_attributes(lead_params)
    respond_to do |format|
      format.js do
        if is_save
          flash[:notice] = "Lead Updated Successfully"
          xhr_redirect_to redirect_to: request.referer
        else
          render_modal 'edit'
        end
      end
      format.html do
        if is_save
          flash[:notice] = "Lead Updated Successfully"
          redirect_to leads_path
        else
          render 'edit'
        end
      end
    end
  end

  def destroy
    if current_user.is_super? && current_user.can_delete_lead?
      if @lead.destroy
        flash[:success] = "Lead Deleted Successfully"
      else
        flash[:danger] = "Cannot Delete this Lead - #{@lead.errors.full_messages.join(', ')}"
      end
    else
      flash[:danger] = "Cannot Delete this Lead - You are not authorized"
    end
    redirect_to request.referer and return
  end

  def edit_visit
    @visits=@lead.visits.find(params[:visit_id])
    render_modal('site_visit_form')
  end

  def perform_import
    if params[:lead_file].present?
      file = params[:lead_file].tempfile
      @success=[]
      @errors=[]
      mf_names = @company.magic_fields.pluck(:name)
      CSV.foreach(file, {:headers=>:first_row, :encoding=> "iso-8859-1:utf-8"}) do |row|
        begin
          name=row["Name"]
          mobile=row["Phone"]
          email= row["Email"]
          other_phones=row["Other Contacts"]
          sub_source = row["Sub Source"]&.strip
          lead_status_id=(@company.statuses.find_id_from_name(row["Lead Status"].strip) rescue nil)
          next_call_date_and_time = Time.zone.parse(row["Next Call Date"].strip) rescue nil
          user_id = (current_user.manageables.find_by_email(row["Assigned To"].strip).id rescue nil)
          project_id = (@company.projects.find_id_from_name(row["Enquiry"].strip) rescue nil)
          source_id = (@company.sources.active.find_id_from_name(row["Lead Source"]) rescue nil)
          broker_id = (@company.brokers.find_id_from_name(row["Channel Partner"]) rescue nil)
          city_id = (City.find_id_from_name(row["City"]) rescue nil)
          comment = row["Description"]
          if row["Dead Reason"].present?
            dead_reason = (@company.find_dead_reason(row["Dead Reason"].strip) rescue nil)
            dead_reason_id = dead_reason&.id
          end
          locality_id = (Locality.find_id_from_name(row["Locality"]) rescue nil)
          created_at = Time.zone.parse(row["Created at"].strip) rescue nil
          lead = @leads.new(
            name: name,
            mobile: mobile,
            other_phones: other_phones,
            email: email,
            status_id: lead_status_id,
            user_id: user_id,
            project_id: project_id,
            source_id: source_id,
            comment: comment,
            ncd: next_call_date_and_time,
            broker_id: broker_id,
            city_id: city_id,
            locality_id: locality_id,
            dead_reason_id: dead_reason_id,
            created_at: created_at
          )
          mf_names.each do |mf_name|
            lead.send("#{mf_name}=", row[mf_name.camelize].to_s.strip)
          end
          if @company.is_allowed_field?('enquiry_sub_source_id')
            lead.enquiry_sub_source_id = (@company.sub_sources.find_id_from_name(sub_source) rescue nil)
          else
            lead.sub_source = sub_source
          end
          if lead.save
            @success << {lead_name: row["Name"], message: "Success"}
          else
            @errors << {lead_name: row["Name"], message: lead.errors.full_messages.join(" | ")}
          end
        rescue Exception => e
          @errors << {lead_name: row["Name"], message: "#{e}"}
        end
      end
    else
      flash[:danger] = "Please upload CSV file."
      redirect_to leads_path
    end
  end

  def import
  end

  def prepare_bulk_update
  end

  def import_bulk_update
    @success = []
    @errors = []
    if params[:leads_file].present?
      CSV.foreach(params[:leads_file].tempfile, {:headers=>:first_row, :encoding=> "iso-8859-1:utf-8"}) do |row|
        lead_no = row["Lead No"].strip rescue nil
        lead_comment = row["Comment"].strip rescue nil
        lead_status_id=(@company.statuses.of_leads.find_id_from_name(row["Lead Status"].strip) rescue nil)
        lead_stage_id = (Stage.where(id: (@company.company_stages.pluck(:stage_id))).find_id_from_name(row["Lead Stage"].strip) rescue nil)
        user_id = (current_user.manageables.find_by_email(row["Assigned To"].strip).id rescue nil)
        dead_reason = (@company.find_dead_reason(row["Dead Reason"].strip) rescue nil)
        source_id = (@company.sources.active.find_id_from_name(row["Lead Source"]) rescue nil)
        lead_next_call_date = (Time.zone.parse(row["Next Call Date"].strip) rescue nil)
        project_id = (@company.projects.find_id_from_name(row["Enquiry"].strip) rescue nil)
        created_at = (Time.zone.parse(row["Created at"].strip) rescue nil)
        begin
          lead = @leads.find_by_lead_no(lead_no)
          if lead.present?
            if lead_comment.present?
              lead.comment = lead_comment
            end
            lead.status_id = lead_status_id.present? ? lead_status_id : lead.status_id
            lead.source_id = source_id.present? ? source_id : lead.source_id
            lead.dead_reason_id = dead_reason.present? ? dead_reason.id : lead.dead_reason_id
            lead.ncd = lead_next_call_date.present? ? lead_next_call_date : lead.ncd
            lead.user_id = user_id.present? ? user_id : lead.user_id
            lead.presale_stage_id = lead_stage_id.present? ? lead_stage_id : lead.presale_stage_id
            lead.project_id = project_id.present? ? project_id : lead.project_id
            lead.created_at = created_at.present? ? created_at : lead.created_at
            if lead.save
              @success << {lead_no: row["Lead No"], :message=>"Success"}
            else
              @errors << {lead_no: row["Lead No"], :message=>"#{lead.errors.full_messages}"}
            end
          else
            @errors << {lead_no: row["Lead No"], :message=>"Lead Not Found"}
          end
        rescue Exception => e
          @errors << {:lead_no=>row["Lead No"], :message=>"#{e}"}
        end
      end
    else
      flash[:alert] = "Please upload CSV file."
      redirect_to prepare_bulk_update_leads_path
    end
  end

  def histories
    @lead_logs = @lead.audits.order(created_at: :desc)
    @lead_call_attempts = @lead.call_attempts.includes(:user).order(updated_at: :desc)
  end

  def make_call
    if @lead.make_call(current_user)
      render json: {success: true}, status: 200
    else
      render json: {success: false}, status: 200
    end
  end

  def call_logs
    @call_logs = Leads::CallLog.includes(:lead).joins{lead}.where(leads: {user_id: current_user.manageables.ids})
    if params[:is_external].present?
      @call_logs = @call_logs.advance_search(call_logs_search_params)
    elsif params[:is_advanced_search].present?
      if params[:call_log_report].present?
        @call_logs = @call_logs.advance_search(call_logs_search_params)
      else
        @call_logs = @call_logs.incoming
        @call_logs = @call_logs.advance_search(call_logs_search_params)
      end
    else
      @call_logs = @call_logs.incoming
      @call_logs = @call_logs.advance_search(call_logs_search_params)
    end
    @call_logs = @call_logs.order("leads_call_logs.start_time DESC").paginate(:page => params[:page], :per_page => PER_PAGE)
  end

  def outbound_logs
    @call_logs = Leads::CallLog.not_incoming.includes(:lead).where(user_id: current_user.manageables.ids)
    if params[:is_advanced_search].present?
      @call_logs = @call_logs.advance_search(outbound_search_params)
    else
      @call_logs = @call_logs
    end
    @call_logs = @call_logs.order("leads_call_logs.updated_at DESC").paginate(:page => params[:page], :per_page => PER_PAGE)
  end

  def dead_or_recycle
    @leads = @leads.joins{audits}.where("((audits.audited_changes -> 'status_id')::jsonb->>1)::INT IN (?)", @company.dead_status_ids.map(&:to_i)).select("DISTINCT ON (audits.associated_id) leads.*")
    if params[:is_advanced_search].present?
      @leads = @leads.advance_search(search_params, current_user)
    end
    @leads = @leads.where(user_id: current_user.manageables.ids).paginate(:page => params[:page], :per_page => PER_PAGE)
  end

  def lead_counts
    @leads = @leads.where(user_id: current_user.manageable_ids)
    today_calls_count=@leads.active_for(current_user.company).todays_calls.count
    backlog_leads_count = @leads.backlogs_for(@company).count
    hot_status_count = @leads.where(status_id: @company.hot_status_ids).count
    new_status_count = @leads.where(status_id: @company.new_status_id).count
    booking_done_count = @leads.where(status_id: @company.booking_done_id).count
    dead_lead_count = @leads.where(status_id: @company.dead_status_ids).count
    respond_to do |format|
      format.json do
        render json: {hot_status_count: hot_status_count, new_status_count: new_status_count, booking_done_count: booking_done_count, dead_lead_count: dead_lead_count, today_calls_count: today_calls_count, backlog_leads_count: backlog_leads_count, status: 200}
      end
    end
  end

  def stages
    @status = @company.statuses.find_by(id: params[:status_id])
    company_stages = @status.fetch_stages(@company).as_api_response(:details)
    render json: company_stages, status: 200 and return
  end

  def localities
    localities = Locality.joins(region: [:city]).where("cities.id=?", params[:id]).as_json(only: [:id, :name])
    render json: localities, status: 200 and return
  end

  private
    def set_lead
      @lead = @leads.find(params[:id])
    end

    def set_leads
      Lead.current_user = current_user
      @company = current_user.company
      @leads = @company.leads
    end

    def loan_params
      params.require(:loan).permit(:user_id, :ncd, :comment)
    end

    def lead_params
      magic_fields = (@company.magic_fields.map{|field| field.name.to_sym} rescue [])
      params.require(:lead).permit(
        *magic_fields,
        :date,
        :name,
        :email,
        :mobile,
        :other_phones,
        :other_emails,
        :address,
        :city,
        :state,
        :country,
        :budget,
        :source_id,
        :sub_source,
        :broker_id,
        :project_id,
        :user_id,
        :closing_executive,
        :ncd,
        :comment,
        :status_id,
        :lead_no,
        :call_in_id,
        :dead_reason_id,
        :dead_sub_reason,
        :city_id,
        :locality_id,
        :tentative_visit_planned,
        :property_type,
        :stage, :referal_name, :referal_mobile,
        :presale_stage_id, :booking_date, :booking_form, :token_date,
        :enquiry_sub_source_id, :customer_type, :lease_expiry_date,
        :visits_attributes=>[:id, :date, :is_visit_executed, :is_postponed, :is_canceled, :comment, :site_visit_form, :location, :surronding, :finalization_period, :loan_sanctioned, :bank_name, :loan_amount, :eligibility, :own_contribution_minimum, :own_contribution_maximum, :loan_requirements, :_destroy, project_ids: []],
        :residential_type_attributes=>[:id, :property_type, :purpose, :plot_area_from, :plot_area_to, :area_config, :area_unit],
        :commercial_type_attributes=>[:id, :property_type, :area_unit, :plot_area_from, :plot_area_to, :is_attached_toilet, :purpose_comment, :purpose]
      )
    end

    def search_params
      magic_fields = (@company.magic_fields.map{|field| field.name.to_sym} rescue [])
      params.permit(
        *magic_fields,
        :name, :visited, :backlogs_only, :todays_call_only, :ncd_from,:exact_ncd_upto, :exact_ncd_from, :created_at_from, :expired_from, :expired_upto, :created_at_upto, :visited_date_from, :booking_date_from, :booking_date_to, :token_date_to, :token_date_from, :visited_date_upto, :ncd_upto,  :email,:state, :mobile, :other_phones, :comment, :lead_no, :manager_id, :budget_from, :site_visit_done, :site_visit_planned, :revisit, :booked_leads, :token_leads, :visit_cancel, :postponed, :budget_upto, :visit_counts, :sub_source, :customer_type, :site_visit_from, :site_visit_upto, dead_reason_ids: [], project_ids: [], :assigned_to => [], :lead_statuses => [], city_ids: [], :source_id=>[],lead_stages: [], :presale_user_id=>[], :sub_source_ids=>[], :lead_ids=>[], broker_ids: [], country_ids: [], closing_executive: [], dead_reasons: [], sv_user: [])
    end

    def call_logs_search_params
      params.permit(
        :past_calls_only,
        :todays_calls,
        :missed_calls,
        :created_at_from,
        :created_at_upto,
        :completed,
        :abandoned_calls,
        :display_from,
        :start_date,
        :end_date,
        :call_direction,
        :first_call_attempt,
        lead_ids: [],
        user_ids: [],
        project_ids: []
      )
    end

    def outbound_search_params
      params.permit(
        :missed_calls,
        :todays_calls,
        :past_calls_only,
        :created_at_from,
        :created_at_upto
      )
    end
end

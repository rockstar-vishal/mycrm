class LoansController < ApplicationController
  before_action :set_loans
  before_action :set_loan, only: [:show, :edit, :update, :destroy]

  respond_to :html
  PER_PAGE = 20

  def index
    @users = current_user.manageables
    if params[:is_advanced_search].present? || params[:search_query].present?
      @loans = @loans.search_base_loans(current_user)
    else
      @loans = @loans.user_loans(current_user)
    end
    if params[:is_advanced_search].present? && params[:search_query].blank?
      @loans = @loans.advance_search(search_params, current_user)
    end

    if params[:search_query].present?
      @loans = @loans.basic_search(params[:search_query], current_user)
    end
    if params[:showable_ids_cs].present?
      @loans = @loans.where(:id=>params[:showable_ids_cs].split(",").uniq)
    end
    if params["key"].present? && params["sort"].present?
      if params["key"] == 'status_id'
        @loans = @loans.includes{status}.order("statuses.name #{params['sort']} NULLS FIRST")
      else
        if @company.setting.present? && @company.enable_ncd_sort_nulls_last && params['sort'] == "desc"
          @loans = @loans.order("#{params['key']} #{params['sort']} NULLS LAST")
        else
          @loans = @loans.order("#{params['key']} #{params['sort']} NULLS FIRST")
        end
      end
    else
      @loans = @loans.order("loans.ncd asc NULLS FIRST, loans.created_at DESC")
    end
    # @leads = @leads.includes{status}.includes{property_type}.includes{transaction_type}.includes{user}.includes{project}.includes{enquiry_source}.includes{outlet_location}
    @loans_count = @loans.size
    respond_to do |format|
      format.html do
        @loans = @loans.includes{lead}.paginate(:page => params[:page], :per_page => PER_PAGE)
      end
      format.csv do
        if @loans_count <= 4000
          send_data @loans.to_csv({}, current_user), filename: "loans_#{Date.today.to_s}.csv"
        else
          render json: {message: "Export of more than 4000 Loan Entries is not allowed in one single attempt. Please contact management for more details"}, status: 403
        end
      end
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

  def update
    is_save = @loan.update_attributes(loan_params)
    respond_to do |format|
      format.js do
        if is_save
          flash[:notice] = "Loan Updated Successfully"
          xhr_redirect_to redirect_to: request.referer
        else
          render_modal 'edit'
        end
      end
      format.html do
        if is_save
          flash[:notice] = "Loan Updated Successfully"
          redirect_to leads_path
        else
          render 'edit'
        end
      end
    end
  end

  def loan_counts
    @loans = @loans.where(user_id: current_user.manageable_ids)
    today_calls_count = @loans.actives.todays_calls.count
    backlog_leads_count = @loans.backlogs_for(@company).count
    hot_status_count = @loans.where(status_id: ::Loan::HOT_STATUS_ID).count
    new_status_count = @loans.where(status_id: ::Loan::DEFAULT_STATUS).count
    booking_done_count = @loans.where(status_id: ::Loan::BOOKED_LOAN_IDS).count
    dead_lead_count = @loans.where(status_id: ::Loan::DEAD_LOAN_IDS).count
    respond_to do |format|
      format.json do
        render json: {hot_status_count: hot_status_count, new_status_count: new_status_count, booking_done_count: booking_done_count, dead_lead_count: dead_lead_count, today_calls_count: today_calls_count, backlog_leads_count: backlog_leads_count, status: 200}
      end
    end
  end

  def destroy

  end

  private
    def set_loan
      @loan = @loans.find(params[:id])
    end

    def set_loans
      Lead.current_user = current_user
      @company = current_user.company
      @loans = @company.loans
    end

    def search_params
      params.permit(
          :name, 
          :mobile,
          :other_phones,
          :email,
          :lead_no,
          :ncd_from,
          :ncd_upto,
          :created_at_from,
          :created_at_upto,
          :visited_date_from,
          :visited_date_upto,
          :visited,
          :backlogs_only,
          :todays_call_only,
          :loan_users=>[],
          :lead_users=>[],
          :dead_reasons=>[],
          :lead_statuses=>[],
          :loan_statuses=>[],
          :source_ids=>[],
          :project_ids=>[]
        )
    end

    def loan_params
      params.require(:loan).permit(
        :ncd, 
        :comment, 
        :status_id, 
        :user_id,
        :dead_reason_id,
        :dead_sub_reason
      )
    end
end

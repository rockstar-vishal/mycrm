class OnsiteLeadsController < ApplicationController
  before_action :set_leads
  before_action :set_lead, only: [:edit]

  respond_to :html
  PER_PAGE = 20

  def index
    @company_leads = @leads
    @leads= @leads.where(user_id: current_user.id).order("created_at desc")
    if params[:search_query].present?
      @leads = @company_leads.basic_search(params[:search_query], current_user)
    end
    @leads_count = @leads.size
    respond_to do |format|
      format.html do
        @leads = @leads.paginate(:page => params[:page], :per_page => PER_PAGE)
      end
      format.pdf do
        @lead = @company_leads.find(params[:lead_id])
        render pdf: "h4a-crm-sv",
              template: "onsite_leads/index_pdf.html.haml",
              locales: {:@lead => @lead},
              :print_media_type => true
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


  private

  def set_lead
    @lead = @leads.find(params[:id])
  end

  def set_leads
    @company = current_user.company
    @leads =@company.leads
  end
end
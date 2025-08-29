class CampaignsController < ApplicationController
  before_action :set_campaigns
  before_action :set_campaign, only: [:show, :edit, :update, :destroy]

  respond_to :html
  PER_PAGE = 20


  def index
    @campaigns = @campaigns.paginate(:page => params[:page], :per_page => PER_PAGE)
  end

  def show
  end


  def new
    @campaign = @campaigns.new
    render_modal 'new'
  end

  def edit
    render_modal 'edit'
  end

  def create
    @campaign = @campaigns.new(campaign_params)
    if @campaign.save
      flash[:notice] = "Campaign created successfully"
      xhr_redirect_to redirect_to: campaigns_path and return
    else
      render_modal 'new'
    end
  end

  def update
    if @campaign.update_attributes(campaign_params)
      flash[:notice] = "Campaign updated successfully"
      xhr_redirect_to redirect_to: campaigns_path
    else
      render_modal 'edit'
    end
  end

  def destroy
    if @campaign.destroy
      flash[:notice] = "Campaign deleted successfully"
    else
      flash[:danger] = "Cannot delete this campaign - #{@campaign.errors.full_messages.join(', ')}"
    end
    redirect_to request.referer and return
  end


  private
    def set_campaign
      @campaign = @campaigns.find_by_uuid params[:uuid]
    end

    def set_campaigns
      @campaigns = current_user.company.campaigns
    end

    def campaign_params
      params.require(:campaign).permit(
        :title,
        :start_date,
        :end_date,
        :company_id,
        :budget,
        :source_id,
        project_ids:[]
      )
    end
end

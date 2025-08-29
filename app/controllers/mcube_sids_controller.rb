class McubeSidsController < ApplicationController

  before_action :set_mcube_sids
  before_action :find_mcube_sid, only: [:edit, :update,:destroy]

  respond_to :html

  PER_PAGE = 20


  def index
    @mcube_sids = @mcube_sids.order(updated_at: :desc).paginate(:page => params[:page], :per_page => PER_PAGE)
  end

  def new
    @mcube_sid = @mcube_sids.new
    render_modal 'new'
  end

  def create
    @mcube_sid = @mcube_sids.new(mcube_params)
    if @mcube_sid.save
      flash[:notice] = 'McubeSid Created Successfully'
      xhr_redirect_to redirect_to: mcube_sids_path and return
    else
      render_modal 'new'
      flash[:alert] = "McubeSid Not Created due to #{@mcube_sid.errors.full_messages.join(',')}"
    end
  end

  def edit
    render_modal 'edit'
  end

  def update
    if @mcube_sid.update_attributes(mcube_params)
      flash[:notice] = 'McubeSid Updated Successfully'
      xhr_redirect_to redirect_to: mcube_sids_path
    else
      render_modal 'edit'
    end
  end

  def destroy
    if @mcube_sid.destroy
      flash[:success] = "McubeSid deleted successfully"
    else
      flash[:danger] = "Cannot delete this McubeSid - #{@mcube_sid.errors.full_messages.join(', ')}"
    end
    redirect_to request.referer and return
  end


  private

  def mcube_params
    params.require(:mcube_sid).permit(
      :number,
      :company_id,
      :description,
      :project_id,
      :is_active
    )
  end

  def set_mcube_sids
    @mcube_sids = current_user.company.mcube_sids
  end

  def find_mcube_sid
    @mcube_sid = @mcube_sids.find_by_uuid params[:uuid]
  end

end

class ExotelSidsController < ApplicationController
	before_action :set_exotel_sids
	before_action :find_exotel, only: [:edit, :update,:destroy]

	respond_to :html
	PER_PAGE = 20


  def index
    @exotel_sids = @exotel_sids.includes(:project).order(updated_at: :desc).paginate(:page => params[:page], :per_page => PER_PAGE)
  end

  def new
    @exotel_sid = @exotel_sids.new
    render_modal 'new'
  end

  def create
    @exotel_sid = @exotel_sids.new(exotel_params)
    if @exotel_sid.save
      flash[:notice] = 'ExoPhone Created Successfully'
      xhr_redirect_to redirect_to: exotel_sids_path and return
    else
      render_modal 'new'
      flash[:alert] = "ExoPhone Not Created due to #{@exotel_sid.errors.full_messages.join(',')}"
    end
  end

  def edit
  	render_modal 'edit'
  end

  def update
    if @exotel_sid.update_attributes(exotel_params)
      flash[:notice] = 'ExoPhone Updated Successfully'
      xhr_redirect_to redirect_to: exotel_sids_path
    else
      render_modal 'edit'
    end
  end

  def statistics
    @call_logs = Leads::CallLog.includes(:lead).joins{lead}.where(leads: {user_id: current_user.manageables.ids})
  end

	def destroy
		if @exotel_sid.destroy
		  flash[:success] = "ExoPhone deleted successfully"
		else
		  flash[:danger] = "Cannot delete this ExoPhone - #{@exotel_sid.errors.full_messages.join(', ')}"
		end
		redirect_to request.referer and return
	end


  private

  def exotel_params
    params.require(:exotel_sid).permit(
      :number,
      :company_id,
      :description,
      :is_active,
      :only_inbound_service,
      :project_id,
      :source_id,
      :is_round_robin_enabled,
      default_numbers: []
    )
  end

  def set_exotel_sids
  	@exotel_sids = current_user.company.exotel_sids
  end

  def find_exotel
    @exotel_sid = @exotel_sids.find_by_uuid params[:uuid]
  end


end

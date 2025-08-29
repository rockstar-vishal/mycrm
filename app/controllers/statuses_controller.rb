class StatusesController < ApplicationController
  before_action :set_status, only: [:show, :edit, :update, :destroy]

  respond_to :html
  PER_PAGE = 50

  def index
    @statuses = Status.all
    @statuses = @statuses.paginate(:page => params[:page], :per_page => PER_PAGE)
  end

  def new
    @status = Status.new
    render_modal 'new'
  end

  def edit
    render_modal('edit')
  end

  def create
    @status = Status.new(status_params)
    if @status.save
      flash[:notice] = 'Status Saved Successfully'
      xhr_redirect_to redirect_to: statuses_path
    else
      flash[:alert] = 'Error!'
      render 'new'
    end
  end

  def update
    if @status.update(status_params)
      flash[:notice] = 'Status Updated Successfully'
      xhr_redirect_to redirect_to: statuses_path
    else
      render 'edit'
    end
  end

  def destroy
    @status.destroy
    respond_with(@status)
  end

  private
    def set_status
      @status = Status.find(params[:id])
    end

    def status_params
      params.require(:status).permit(:name, :class_name)
    end
end

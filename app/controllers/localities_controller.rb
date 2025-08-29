class LocalitiesController < ApplicationController
  before_action :set_locality, only: [:show, :edit, :update]

  PER_PAGE = 50

  def index
    @localities = Locality.includes(:region).order("localities.created_at DESC")
    if params[:search_string].present?
      @localities = @localities.basic_search(params[:search_string])
    end
    @localities = @localities.paginate(page: params[:page], per_page: PER_PAGE)
  end

  def new
    @locality = Locality.new
    render_modal('new')
  end

  def create
    @locality = Locality.new(locality_params)
    if @locality.save
      flash[:notice] = "#{@locality.name} - Locality Created Successfully"
      xhr_redirect_to redirect_to: localities_path
    else
      flash[:alert] = 'Error!'
      render_modal 'new'
    end
  end

  def show
  end

  def edit
    render_modal('edit')
  end

  def update
    if @locality.update_attributes(locality_params)
      flash[:notice] = "#{@locality.name} - Locality Updated Successfully"
      xhr_redirect_to redirect_to: localities_path
    else
      render_modal('edit')
    end
  end

  private

  def locality_params
    params.require(:locality).permit(
      :name,
      :region_id
    )
  end

  def set_locality
    @locality = Locality.find(params[:id])
  end
end

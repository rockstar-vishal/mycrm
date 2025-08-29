class RegionsController < ApplicationController
  before_action :set_region, only: [:show, :edit, :update]

  PER_PAGE = 50

  def index
    @regions = Region.includes(:city).order("regions.created_at DESC")
    if params[:search_string].present?
      @regions = @regions.basic_search(params[:search_string])
    end
    @regions = @regions.paginate(page: params[:page], per_page: PER_PAGE)
  end

  def new
    @region = Region.new
    render_modal('new')
  end

  def create
    @region = Region.new(region_params)
    if @region.save
      flash[:notice] = "#{@region.name} - Region Created Successfully"
      xhr_redirect_to redirect_to: regions_path
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
    if @region.update_attributes(region_params)
      flash[:notice] = "#{@region.name} - Region Updated Successfully"
      xhr_redirect_to redirect_to: regions_path
    else
      render_modal('edit')
    end
  end

  private

  def region_params
    params.require(:region).permit(
      :name,
      :city_id
    )
  end

  def set_region
    @region = Region.find(params[:id])
  end
end

class CitiesController < ApplicationController
  before_action :set_city, only: [:show, :edit, :update, :destroy, :localities]

  PER_PAGE = 50
  respond_to :html

  def index
    @cities = City.all
    if params[:search_string].present?
      @cities = @cities.basic_search(params[:search_string])
    end
    @cities = @cities.paginate(:page => params[:page], :per_page => PER_PAGE)
  end

  def show
    respond_with(@city)
  end

  def new
    @city = City.new
    render_modal('new')
  end

  def edit
    render_modal('edit')
  end

  def create
    @city = City.new(city_params)
    if @city.save
      flash[:notice] = 'City Saved Successfully'
      xhr_redirect_to redirect_to: cities_path
    else
      flash[:alert] = 'Error!'
      render_modal 'new'
    end
  end

  def update
    if @city.update_attributes(city_params)
      flash[:notice] = 'City Updated Successfully'
      xhr_redirect_to redirect_to: cities_path
    else
      render_modal('edit')
    end
  end

  def destroy
    @city.destroy
    respond_with(@city)
  end

  private
    def set_city
      @city = City.find(params[:id])
    end

    def city_params
      params.require(:city).permit(:name)
    end
end

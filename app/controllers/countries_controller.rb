class CountriesController < ApplicationController
    before_action :set_country, only: [:show, :edit, :update]
  
    PER_PAGE = 50
  
    def index
      @countries = Country.all
      @countries = @countries.paginate(page: params[:page], per_page: PER_PAGE)
    end
  
    def new
      @country = Country.new
      render_modal('new')
    end
  
    def create
      @country = Country.new(country_params)
      if @country.save
        flash[:notice] = "#{@country.name} - Country Created Successfully"
        xhr_redirect_to redirect_to: countries_path
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
      if @country.update_attributes(country_params)
        flash[:notice] = "#{@country.name} - country Updated Successfully"
        xhr_redirect_to redirect_to: countries_path
      else
        render_modal('edit')
      end
    end
  
    private
  
    def country_params
      params.require(:country).permit(
        :name
      )
    end
  
    def set_country
      @country = Country.find(params[:id])
    end
  end
  
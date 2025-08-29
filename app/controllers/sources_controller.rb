class SourcesController < ApplicationController
  before_action :set_source, only: [:show, :edit, :update, :destroy]

  PER_PAGE = 50
  respond_to :html

  def index
    @sources = Source.all
    @sources = @sources.paginate(:page => params[:page], :per_page => PER_PAGE)
  end

  def new
    @source = Source.new
    render_modal('new')
  end

  def edit
    render_modal('edit')
  end

  def create
    @source = Source.new(source_params)
    if @source.save
      flash[:notice] = 'Source Saved Successfully'
      xhr_redirect_to redirect_to: sources_path
    else
      flash[:alert] = 'Error!'
      render_modal 'new'
    end
  end

  def update
    if @source.update_attributes(source_params)
      flash[:notice] = 'Source Updated Successfully'
      xhr_redirect_to redirect_to: sources_path
    else
      flash[:alert] = 'Error!'
      render_modal 'edit'
    end
  end

  def destroy
    @source.destroy
    respond_with(@source)
  end

  private
    def set_source
      @source = Source.find(params[:id])
    end

    def source_params
      params.require(:source).permit(:name, :active, :is_cp, :is_digital, :is_reference)
    end
end

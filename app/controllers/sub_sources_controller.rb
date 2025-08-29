class SubSourcesController < ApplicationController
  before_action :set_sub_sources
  before_action :set_sub_source, only: [:show, :edit, :update, :destroy]

  respond_to :html
  PER_PAGE = 20
  # GET /sub_sources
  # GET /sub_sources.json
  def index
    @sub_sources = @sub_sources.paginate(:page => params[:page], :per_page => PER_PAGE)
  end

  # GET /sub_sources/1
  # GET /sub_sources/1.json
  def show
  end

  def edit
    render_modal 'edit'
  end

  def new
    @sub_source = @sub_sources.new
    render_modal 'new'
  end

  # POST /sub_sources
  def create
    @sub_source = SubSource.new(sub_source_params)
    @sub_source.company_id = @company.id if @sub_source.company_id.blank?
    if @sub_source.save
      flash[:success] = "Sub source created successfully"
      xhr_redirect_to redirect_to: sub_sources_path
    else
      render_modal 'new'
    end
  end

  # PATCH/PUT /sub_sources/1
  def update
    if @sub_source.update_attributes(sub_source_params)
      flash[:notice] = "Sub source updated successfully"
      xhr_redirect_to redirect_to: sub_sources_path
    else
      render_modal 'edit'
    end
  end

  # DELETE /sub_sources/1
  def destroy
    if @sub_source.destroy
      flash[:success] = "sub source deleted successfully"
    else
      flash[:danger] = "Cannot delete this Subsource - #{@sub_source.errors.full_messages.join(', ')}"
    end
  end

  private

    def set_sub_sources
      @company = current_user.company
      @sub_sources = @company.sub_sources
    end

    def set_sub_source
      @sub_source = @sub_sources.find_by_uuid params[:uuid]
    end

    def sub_source_params
      params.require(:sub_source).permit(:name, :company_id)
    end
  end
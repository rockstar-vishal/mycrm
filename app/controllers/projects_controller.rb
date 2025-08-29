class ProjectsController < ApplicationController
  before_action :set_projects
  before_action :set_project, only: [:show, :edit, :update, :destroy]

  respond_to :html
  PER_PAGE = 20

  def index
    @projects = @projects
    if params[:search_string].present?
      @projects = @projects.basic_search(params[:search_string])
    end
    @projects = @projects.paginate(:page => params[:page], :per_page => PER_PAGE)
  end

  def show
  end

  def new
    @project = @projects.new
    render_modal 'new'
  end

  def edit
    render_modal 'edit'
  end

  def create
    @project = @projects.new(project_params)
    if @project.save
      flash[:notice] = "Project created successfully"
      xhr_redirect_to redirect_to: projects_path and return
    else
      render_modal 'new'
    end
  end

  def update
    if @project.update_attributes(project_params)
      flash[:notice] = "Project updated successfully"
      xhr_redirect_to redirect_to: projects_path
    else
      render_modal 'edit'
    end
  end

  def destroy
    if @project.destroy
      flash[:success] = "Project deleted successfully"
    else
      flash[:danger] = "Cannot delete this project - #{@project.errors.full_messages.join(', ')}"
    end
    redirect_to request.referer and return
  end

  private
    def set_project
      @project = @projects.find_by_uuid params[:uuid]
    end

    def set_projects
      @projects = current_user.company.projects
    end

    def project_params
      params.require(:project).permit(
        :name,
        :company_id,
        :city_id,
        :address,
        :active,
        :housing_token,
        :mb_token,
        :cross_pitch,
        :nine_token,
        :is_default,
        :country_id,
        property_codes: [],
        dyn_assign_user_ids: [],
        fb_ads_ids_attributes: [
          :id,
          :number,
          :_destroy
        ]
      )
    end
end

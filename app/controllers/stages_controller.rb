class StagesController < ApplicationController

  before_action :set_stages
  before_action :set_stage, only: [:show, :edit, :update, :destroy]

  respond_to :html
  PER_PAGE = 20

  def index
    @stages = @stages.order(updated_at: :desc).paginate(:page => params[:page], :per_page => PER_PAGE)
  end

  def show
  end

  def new
    @stage = @stages.new
    render_modal('new')
  end

  def edit
    render_modal('edit')
  end

  def create
    @stage = @stages.new(stage_params)
    if @stage.save
      flash[:notice] = "Stage created successfully"
      xhr_redirect_to redirect_to: stages_path
    else
      render_modal('new')
    end
  end

  def update
    if @stage.update_attributes(stage_params)
      flash[:notice] = "Stage updated successfully"
      xhr_redirect_to redirect_to: stages_path
    else
      render_modal 'edit'
    end
  end

  private

    def set_stages
      @stages = Stage.all
    end

    def set_stage
      @stage = @stages.find_by_uuid params[:uuid]
    end

    def stage_params
      params.require(:stage).permit(:name)
    end
end

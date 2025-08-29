class NotificationTemplatesController < ApplicationController
  before_action :set_templates
  before_action :set_template, only: [:show, :edit, :update, :destroy]

  respond_to :html
  PER_PAGE = 20

  def index
    @templates = @templates.paginate(:page => params[:page], :per_page => PER_PAGE)
  end

  def new
    @template = @templates.new
    render_modal 'new'
  end

  def edit
    render_modal('edit')
  end

  def create
    @template = @templates.new(template_params)
    if @template.save
      flash[:success] = "Template created successfully"
      xhr_redirect_to redirect_to: notification_templates_path
    else
      render_modal 'new'
    end
  end

  def update
    if @template.update_attributes(template_params)
      flash[:success] = "Template updated successfully"
      xhr_redirect_to redirect_to: notification_templates_path
    else
      render_modal 'edit'
    end
  end

  def destroy
    if @template.destroy
      flash[:success] = "Template deleted successfully"
    else
      flash[:danger] = "Cannot delete this template - #{@template.errors.full_messages.join(', ')}"
    end
    redirect_to notification_templates_path and return
  end

  private
    def set_template
      @template = @templates.find_by_uuid params[:uuid]
    end

    def set_templates
      @templates = current_user.company.notification_templates
    end

    def template_params
      params.require(:notification_template).permit(:name, :body, :fields, :template_id)
    end
end

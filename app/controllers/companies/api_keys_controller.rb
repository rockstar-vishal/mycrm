class Companies::ApiKeysController < ApplicationController
  before_action :set_keys
  before_action :set_key, only: [:show, :edit, :update, :destroy]

  respond_to :html
  PER_PAGE = 20

  def index
    @keys = @keys.paginate(:page => params[:page], :per_page => PER_PAGE)
  end

  def show
  end

  def new
    @key = @keys.new
    render_modal 'new'
  end

  def edit
    render_modal('edit')
  end

  def create
    @key = @keys.build(key_params)
    if @key.save
      flash[:notice] = "API Keys created successfully"
      xhr_redirect_to redirect_to: companies_api_keys_path
    else
      render_modal 'new'
    end
  end

  def update
    if @key.update_attributes(key_params)
      flash[:notice] = "API Keys updated successfully"
      xhr_redirect_to redirect_to: companies_api_keys_path
    else
      render_modal 'edit'
    end
  end

  def destroy
    if @key.destroy
      flash[:notice] = "Deleted Successfully"
    else
      flash[:danger] = "Cannot Delete this key - #{@key.errors.full_messages.join(', ')}"
    end
    redirect_to request.referer and return
  end

  private
    def set_keys
      @keys = current_user.company.api_keys
    end
    def set_key
      @key = @keys.find_by_uuid params[:uuid]
    end

    def key_params
      params.require(:companies_api_key).permit(:source_id, :user_id, :project_id)
    end
end

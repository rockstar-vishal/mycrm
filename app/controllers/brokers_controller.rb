class BrokersController < ApplicationController
  before_action :set_brokers
  before_action :set_broker, only: [:show, :edit, :update, :destroy]

  respond_to :html
  PER_PAGE = 20
  # GET /brokers
  # GET /brokers.json
  def index
    if params[:search_query].present?
      @brokers = @brokers.basic_search(params[:search_query])
    end
    @brokers = @brokers.paginate(:page => params[:page], :per_page => PER_PAGE)
  end

  # GET /brokers/1
  # GET /brokers/1.json
  def show
  end

  def edit
    render_modal 'edit'
  end

  def new
    @broker = @brokers.new
    render_modal 'new'
  end

  # POST /brokers
  def create
    @broker = Broker.new(broker_params)
    @broker.company_id = @company.id if @broker.company_id.blank?
    if @broker.save
      flash[:success] = "Broker created successfully"
      xhr_redirect_to redirect_to: brokers_path
    else
      render_modal 'new'
    end
  end

  # PATCH/PUT /brokers/1
  def update
    if @broker.update_attributes(broker_params)
      flash[:notice] = "Broker updated successfully"
      xhr_redirect_to redirect_to: brokers_path
    else
      render_modal 'edit'
    end
  end

  # DELETE /brokers/1
  def destroy
    if @broker.destroy
      flash[:success] = "Broker deleted successfully"
    else
      flash[:danger] = "Cannot delete this broker - #{@broker.errors.full_messages.join(', ')}"
    end
  end

  private

    def set_brokers
      @company = current_user.company
      @brokers = @company.brokers
    end

    def set_broker
      @broker = @brokers.find_by_uuid params[:uuid]
    end

    def broker_params
      params.require(:broker).permit(:name, :email, :mobile, :firm_name, :locality, :rera_number, :company_id, :rm_id, :other_contacts)
    end
end

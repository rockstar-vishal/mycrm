class CallInsController < ApplicationController
  before_action :set_call_ins
  before_action :set_call_in, only: [:show, :edit, :update, :destroy]

  respond_to :html
  PER_PAGE = 20

  def index
    @call_ins = @call_ins.paginate(:page => params[:page], :per_page => PER_PAGE)
  end

  def show
  end

  def new
    @call_in = @call_ins.new
    render_modal('new')
  end

  def edit
    render_modal('edit')
  end

  def create
    @call_in = @call_ins.new(call_in_params)
    if @call_in.save
      flash[:notice] = "Call In created successfully"
      xhr_redirect_to redirect_to: call_ins_path
    else
      render_modal('new')
    end
  end

  def update
    if @call_in.update_attributes(call_in_params)
      flash[:notice] = "Call In updated successfully"
      xhr_redirect_to redirect_to: call_ins_path
    else
      render_modal 'edit'
    end
  end

  def destroy
    if @call_in.destroy
      flash[:success] = "Call In deleted successfully"
    else
      flash[:danger] = "Cannot delete this Call In - #{@call_in.errors.full_messages.join(', ')}"
    end
    redirect_to call_ins_path and return
  end

  private
    def set_call_ins
      if current_user.is_sysad?
        @call_ins = ::CallIn.all
      else
        @call_ins = current_user.company.call_ins
      end
    end

    def set_call_in
      @call_in = @call_ins.find_by_uuid params[:uuid]
    end

    def call_in_params
      permitted = params.require(:call_in).permit(:project_id, :user_id, :source_name, :active)
      permitted.merge!(company_id: params[:call_in][:company_id], :number=>params[:call_in][:number]) if current_user.is_sysad?
      return permitted
    end
end

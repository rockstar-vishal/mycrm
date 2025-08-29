class UsersController < ApplicationController
  before_action :set_users, except: [:edit_profile, :update_profile, :edit_user_config]
  before_action :set_user, only: [:show, :edit, :update, :destroy]

  respond_to :html
  PER_PAGE = 50

  def index
    @users = @users.paginate(:page => params[:page], :per_page => PER_PAGE)
  end

  def show
    render_modal('show', {:class=>'right'})
  end

  def new
    @user = @users.new
  end

  def edit
  end

  def create
    @user = @users.new(user_params)
    if @user.save
      flash[:notice] = "User created successfully"
      redirect_to users_path and return
    else
      render 'new'
    end
  end

  def update
    if params[:user][:password].blank?
      params[:user].delete(:password)
      params[:user].delete(:password_confirmation)
    end
    if @user.update_attributes(user_params)
      flash[:notice] = "User updated successfully"
      redirect_to users_path and return
    else
      render 'edit'
    end
  end

  def edit_profile
    @user = current_user
  end

   def update_profile
    @user = current_user
    if params[:user][:password].blank?
      params[:user].delete(:password)
      params[:user].delete(:password_confirmation)
    end
    if @user.update_attributes(user_profile_params)
      flash[:success] = 'Updated Successfully'
      redirect_to request.referer and return
    else
      render 'edit_profile'
    end
  end

  def edit_user_config
    @users = current_user.manageables
    render_modal 'edit_user_config'
  end

  def enable_round_robin
    current_user.manageables.each do |user|
      if params[:users_list].present?
        params[:users_list].include?(user.id.to_s) ? user.update_attributes(:round_robin_enabled => true) : user.update_attributes(:round_robin_enabled => false)
      end
    end
    company = current_user.company
    if company.update_attributes(:round_robin_enabled => true)
      flash[:notice] = "Round Robin Assignment enabled successfully"
    else
      flash[:alert] = "Cannot enable Round Robin Assignment - #{company.errors.full_messages.join(', ')}"
    end
    redirect_to configurations_path and return
  end

  def disable_round_robin
    company = current_user.company
    current_user.manageables.round_robin_users.each do |user|
      user.update_attributes(:round_robin_enabled=>false)
    end
    if company.update_attributes(:round_robin_enabled => false)
      flash[:notice]  = "Round Robin Assignment disabled successfully"
    else
      flash[:alert] = "Cannot disable this functionality - #{company.errors.full_messages.join(',')}"
    end
    redirect_to request.referer and return
  end

  def destroy
    if @user.destroy
      flash[:success] = "User deleted successfully"
    else
      flash[:danger] = "Cannot delete this User - #{@user.errors.full_messages.join(', ')}"
    end
    redirect_to users_path and return
  end

  private
    def set_user
      @user = @users.find_by_uuid params[:uuid]
    end

    def set_users
      if current_user.is_sysad?
        @users = ::User.superadmins
      else
        if current_user.is_super?
          @users = current_user.company.users
        else
          @users = current_user.manageables
        end
      end
    end

    def user_params
      permitted = params.require(:user).permit(
        :name,
        :mobile,
        :email,
        :role_id,
        :city_id,
        :state,
        :country,
        :active,
        :role_id,
        :click_to_call_enabled,
        :exotel_sid_id,
        :mcube_sid_id,
        :loan_enabled,
        :is_cross_pitch,
        :round_robin_enabled,
        :can_import,
        :can_delete_lead,
        :password,
        :password_confirmation,
        :caller_desk_project_id,
        :agent_id,
        :is_meeting_executive,
        :is_calling_executive,
        :manager_mappings_attributes=>[:id, :_destroy, :manager_id],
        :round_robin_settings_attributes => [:id, :_destroy, :source_id, :sub_source_id, :project_id],
        :users_projects_attributes => [:id, :_destroy, :project_id, :user_id]
      )
      permitted.merge!(company_id: params[:user][:company_id]) if current_user.is_sysad?
      permitted
    end

    def user_profile_params
      params.require(:user).permit(
        :name,
        :mobile,
        :email,
        :password,
        :password_confirmation,
        :image
      )
    end
end

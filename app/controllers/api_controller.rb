class ApiController < ActionController::API
  include ActionController::HttpAuthentication::Token::ControllerMethods
  before_action :authenticate, except: [:login]

  def login
    render json: {status: false, message: "Email / Password not sent"}, status: 400 and return if params[:email].blank? || params[:password].blank?
    user = ::User.active.find_by_email params[:email]
    if user.present?
      if user.valid_password? params[:password]
        render json: {status: false, message: "You are not allowed to access this app"}, status: 422 and return if user.is_sysad?
        token = user.tokens.build
        if token.save
          signature = nil
          if user.company.present? && user.company.can_send_push_notification?
            Pushpad.auth_token = user.company.push_notification_setting.token
            Pushpad.project_id = user.company.push_notification_setting.project_key
            signature = Pushpad.signature_for user.uuid
          end
          render json: {data: {user_id: user.id, email: user.email, token: token.token, name: user.name, role: user.role.name, company_name: user.company.name, push_notification_allowed: user.company.can_send_push_notification?, user_uuid: user.uuid, signature: signature, project_key: user.company.push_notification_setting&.project_key, auth_key: user.company.push_notification_setting&.token}}, status: 200 and return
        else
          render json: {status: false, message: token.errors.full_messages.join(', ')}, status: 422 and return
        end
      else
        render json: {status: false, message: "Password Invalid"}, status: 422 and return
      end
    else
      render json: {status: false, message: "Email Invalid"}, status: 404 and return
    end
  end

  def logout
    @current_app_user.tokens.each do |token|
      token.destroy
    end
    render json: {status: true, message: "Success"}, status: 200 and return
  end

  protected
    def authenticate
      authenticate_token || render_unauthorized
    end

    def authenticate_token
      authenticate_with_http_token do |token, options|
        user_token = ::Users::Token.joins(:user).where({user: {active: true}}).find_by(token: token)
        @current_app_user = user_token.user if user_token.present?
        return true if @current_app_user.present?
      end
    end

    def render_unauthorized
      render json: {status: false, message: 'Invalid Authentication'}, status: 401
    end

end
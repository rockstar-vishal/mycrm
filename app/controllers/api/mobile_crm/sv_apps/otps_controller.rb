module Api

  module MobileCrm

    module SvApps

      class OtpsController < ::Api::MobileCrm::SiteVisitInformationsController

        before_action :find_company, :set_api_key
        before_action :authenticate, except: [:create, :validate]

        def create
          is_otp_generated, otp = @company.generate_sms_otp(
              {validatable_data: otp_params[:mobile], event_type: 'sv_visit'}
            )
          if is_otp_generated
            render json: {success: true, message: 'otp created'}, status: 201
          else
            render json: {success: false}, status: 422
          end
        end

        def validate
          if @company.validate_otp({otp: params[:otp], event_type: 'sv_visit', validatable_data: params[:mobile]})
            render json: {success: true, message: 'otp validated'}, status: 202
          else
            render json: {success: false, message: 'Invalid Otp'}, status: 401
          end
        end


        def otp_params
          params.require(:params).permit(
            :mobile
          )

        end

      end

    end

  end

end
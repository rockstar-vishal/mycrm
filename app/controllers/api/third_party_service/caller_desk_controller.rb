module Api

  module ThirdPartyService

    class CallerDeskController < PublicApiController

      before_action :find_company

      DATA_HASH = {
        "8884898765" => '0714749d-e8b6-45cf-989b-b402c34eb574',
        "9212222900" => '0714749d-e8b6-45cf-989b-b402c34eb574'
      }

      def hangup
        user = @company.users.find_by(mobile: call_params["DialWhomNumber"]&.last(10)) || @company.users.active.superadmins.first
        project_id =  (user.caller_desk_project_id || @company.default_project&.id)
        phone = call_params["SourceNumber"]&.last(10)
        user_id = user&.id
        @leads = @company.leads.active_for(@company).where(:project_id=>project_id).where("( mobile LIKE ?)", "%#{phone.last(10) if phone.present?}%")
        if @leads.present?
          @lead = @leads.last
        else
          @lead = @company.leads.new(
            mobile: phone,
            project_id: project_id,
          )
        end
        @lead.assign_attributes(
          name: @lead.name || '--',
          status_id: @lead.status_id || @company.new_status_id,
          source_id:  2,
          user_id: @lead.user_id || user_id
        )
        if @lead.save
          @lead.call_logs.create(
            user_id: @lead.user_id,
            caller: 'Lead',
            sid: call_params["CallSid"],
            start_time: call_params["StartTime"],
            from_number: @lead.mobile,
            to_number: call_params["DialWhomNumber"],
            end_time: call_params["EndTime"],
            recording_url: call_params["CallRecordingUrl"],
            duration: call_params["CallDuration"],
            direction: 'incoming',
            status: call_params["Status"],
            third_party_id: 'callerdesk'
          )
          render json: {staus: 200}
        else
          render :json=>{:status=>"Failure"}
        end
      end

      private

      def find_company
        @company = Company.find_by(uuid: DATA_HASH[params["DestinationNumber"]]) rescue nil
        if @company.blank?
          render json: {status: false, message: "Invalid IVR"}, status: 400 and return
        end
      end

      def call_params
        params.permit(
          :SourceNumber,
          :DestinationNumber,
          :DialWhomNumber,
          :CallDuration,
          :Status,
          :StartTime,
          :EndTime,
          :CallRecordingUrl,
          :CallSid,
          :Direction,
          :TalkDuration
        )
      end

    end

  end

end

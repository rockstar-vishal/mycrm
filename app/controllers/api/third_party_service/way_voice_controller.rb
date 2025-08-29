module Api

  module ThirdPartyService

    class WayVoiceController < PublicApiController

      PHONE_SID_POOL = {
        "46e2641a-a25b-4286-a704-1dd5c9c317a8" => '07127135984',
        "c32baa8f-726f-49a6-9079-dd44d27bdabe" => "09607000405"
      }


      before_action :find_company

      def outbound_disconnect
        @call_log = ::Leads::CallLog.where(sid: way_voice_params["refid"]).last
        if @call_log.present?
          if @call_log.update(
            end_time: way_voice_params["EndTime"],
            recording_url: way_voice_params["recordingurl"],
            duration: ((Time.zone.parse(way_voice_params["EndTime"]) - @call_log.start_time) rescue nil),
            status: way_voice_params["CallStatus"],
          )
            render :json=>{:status=>"Success"}
          else
            render :json=>{:status=>"Failure"}
          end
        else
          render :json=>{:status=>"Failure", message: 'Invalid Call Reference ID'}
        end
      end

      def incoming_call
        project_id =  @company.default_project&.id
        phone = way_voice_params["CallerNo"]&.last(10)
        user_id = @company.users.find_by(mobile: way_voice_params["AgentNo"]&.last(10))&.id
        @leads = @company.leads.active_for(@company).where(:project_id=>project_id).where("( mobile LIKE ?)", "%#{phone.last(10) if phone.present?}%")
        if @leads.present?
          @lead = @leads.last
        else
          @lead = @company.leads.new(
            mobile: phone,
            project_id: project_id
          )
        end
        @lead.assign_attributes(
          name: @lead.name || '--',
          status_id: @lead.status_id || @company.new_status_id,
          source_id:  @lead.source_id || 2,
          user_id: @lead.user_id || user_id
        )
        if @lead.save
          @lead.call_logs.create(
            user_id: user_id,
            caller: 'Lead',
            sid: SecureRandom.uuid,
            start_time: way_voice_params["StartTime"],
            from_number: phone,
            to_number: way_voice_params["AgentNo"],
            end_time: way_voice_params["EndTime"],
            recording_url: way_voice_params["recordingurl"],
            duration: (Time.zone.parse(way_voice_params["EndTime"]) - Time.zone.parse(way_voice_params["StartTime"]) rescue nil),
            direction: 'incoming',
            phone_number_sid: (PHONE_SID_POOL.select{|sid| sid==params["uuid"] }.values[0] rescue nil),
            status: way_voice_params["CallStatus"],
            call_type: 'Inbound'
          )
          render json: {staus: 200}
        else
          render :json=>{:status=>"Failure"}
        end
      end


      private

      def find_company
        @company = Company.find_by(uuid: params["uuid"]) rescue nil
        if @company.blank?
          render json: {status: false, message: "Invalid IVR"}, status: 400 and return
        end
      end

      def way_voice_params
        params.permit(
          :CallerNo,
          :CallDate,
          :StartTime,
          :EndTime,
          :AgentNo,
          :CallStatus,
          :recordingurl,
          :refid
        )
      end

    end

  end

end

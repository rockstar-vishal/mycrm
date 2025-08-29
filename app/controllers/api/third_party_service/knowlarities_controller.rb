module Api

  module ThirdPartyService

    class KnowlaritiesController < PublicApiController

      before_action :find_company

      SETTING_HASH = {
        "8291935811"=> {source_id: 10},
        "8291935822" => {source_id: 102},
        "9513166762" => {source_id: 120},
        "9513166763" => {source_id: 120}
      }

      PROJECT_HASH = {
        "9513166762" => {project_id: 833},
        "9513166763" => {project_id: 822}
      }


      def incoming_call
        project_id =  (PROJECT_HASH.select{|sh| sh[knowlarities_params["dispnumber"].last(10)]}.values.first[:project_id] rescue @company.default_project&.id)
        phone = knowlarities_params["caller_id"]&.last(10)
        user_id = @company.users.find_by(mobile: knowlarities_params["destination"]&.last(10))&.id
        @leads = @company.leads.active_for(@company).where(:project_id=>project_id).where("( mobile LIKE ?)", "%#{phone.last(10) if phone.present?}%")
        selected_source_id = (SETTING_HASH.select{|sh| sh[knowlarities_params["dispnumber"].last(10)]}.values.first[:source_id] rescue 2)
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
          source_id:  @lead.source_id || selected_source_id,
          user_id: @lead.user_id || user_id
        )
        if @lead.save
          @lead.call_logs.create(
            user_id: user_id,
            caller: 'Lead',
            sid: knowlarities_params["callid"],
            start_time: Time.zone.parse(knowlarities_params["start_time"]),
            from_number: phone,
            to_number: knowlarities_params["destination"],
            end_time: Time.zone.parse(knowlarities_params["end_time"]),
            recording_url: knowlarities_params["resource_url"],
            duration: knowlarities_params["call_duration"],
            direction: 'incoming',
            phone_number_sid: knowlarities_params["dispnumber"],
            status: (knowlarities_params["call_duration"].to_i > 0  ? 'ANSWER' : 'Missed'),
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

      def knowlarities_params
        params.permit(
          :dispnumber,
          :caller_id,
          :start_time,
          :end_time,
          :call_duration,
          :callid,
          :destination,
          :resource_url
        )
      end

    end

  end

end

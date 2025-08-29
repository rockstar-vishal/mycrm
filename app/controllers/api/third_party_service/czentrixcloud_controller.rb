module Api

  module ThirdPartyService

    class CzentrixcloudController < PublicApiController

      def dialwhom
        customer_no = params[:call_id]
        # TODO - Replace with Request host for multiple Clients
        company = Company.find(37)
        leads = company.leads.where("( mobile LIKE ?)", "%#{customer_no.last(10) if customer_no.present?}%")
        if leads.present?
          lead = leads.last
          user = lead.user
          render json: {campaignName: "Fashion_TV", agent_id: user.agent_id, agent_no: user.mobile&.last(10) ,customerPhone: customer_no}, status: 200
        else
          render json: {campaignName: "Fashion_TV", agent_id: '', agent_no: '' ,customerPhone: customer_no}, status: 404
        end
      end

      def incoming_call_connect
        user = User.find_by(agent_id: czentrix_params["agent_id"])
        company = user.company
        project_id =  company.default_project&.id
        phone = czentrix_params["phone_no"]&.last(10) || czentrix_params["phone"]&.last(10)
        user_id = user&.id
        if czentrix_params[:unique_id].present?
          lead = company.leads.find_by(id: czentrix_params[:unique_id])
        else
          leads = company.leads.where.not(status_id: company.dead_status_ids).where("((mobile != '' AND mobile IS NOT NULL) AND RIGHT(REPLACE(mobile,' ', ''), 10) LIKE ?)", "#{phone.last(10) if phone.present?}")
          if leads.present?
            lead = leads.last
          else
            lead = company.leads.new(
              mobile: phone,
              project_id: project_id
            )
          end
        end
        lead.assign_attributes(
          name: lead.name || '--',
          status_id: lead.status_id || company.new_status_id,
          source_id:  lead.source_id || 2,
          user_id: lead.user_id || user_id
        )
        if lead.save
          lead.call_logs.create(
            third_party_id: 4,
            user_id: lead.user_id,
            caller: (czentrix_params["call_type"] == "OUTBOUND" ? 'User' : 'Lead'),
            sid: lead.generate_uniq_ssid,
            session_id: czentrix_params["session_id"],
            start_time: (czentrix_params["call_start_date_time"].present? ? Time.zone.at(czentrix_params["call_start_date_time"]) : Time.zone.now rescue (Time.zone.now)),
            from_number: (czentrix_params["call_type"] == "OUTBOUND" ? user.mobile : phone),
            status: czentrix_params["call_status"],
            to_number: (czentrix_params["call_type"] == "OUTBOUND" ? phone : user.mobile),
            direction: (czentrix_params["call_type"] == "OUTBOUND" ? 'outbound' : 'incoming'),
            call_type: (czentrix_params["call_type"] == "OUTBOUND" ? 'outbound' : 'incoming')
          )
          render json: {staus: 200}
        else
          render :json=>{:status=>"Failure"}
        end
      end

      def incoming_call_disconnect
        call_log = Leads::CallLog.where("leads_call_logs.other_data->>'session_id' = ?", czentrix_params[:session_id]).last
        @user = User.active.find_by(agent_id: czentrix_params[:agent_id])
        comment = czentrix_params["comment"]
        ncd = Time.zone.parse(czentrix_params["ncd"]) rescue ""
        if call_log.present?
          lead = call_log.lead
          if call_log.update(
            end_time: (Time.zone.parse(czentrix_params[:date_time])+czentrix_params[:call_duration].to_i rescue Time.zone.now),
            duration: czentrix_params[:call_duration],
            status: czentrix_params[:call_status]
          )
            begin
              require 'nokogiri'
              response = RestClient.get("https://agent.c-zentrixcloud.com/playmediaAPI.php?session_id=#{call_log.session_id}&agent_id=#{call_log.user&.agent_id}")
              document = Nokogiri::HTML.parse(response)
              recording_prefix = document.at("source").attributes["src"].value rescue ""
              recording_url = recording_prefix.present? ? "https://agent.c-zentrixcloud.com/#{recording_prefix}" : ""
              call_log.update(recording_url: recording_url)
            rescue => e
            end
            if lead.present?
              lead.ncd = ncd.present? ? ncd : lead.ncd
              if Leads::CallLog::ANSWERED_STATUS.include?(call_log.status) && !lead.is_repeated_call?
                lead.user_id= @user.id
              end
              lead.save
            end
            render :json=>{:status=>"Success"}
          else
            render :json=>{:status=>"Failure"}
          end
        else
          render :json=>{:status=>"Invalid Session ID"}, status: 400
        end
      end

      private

      def czentrix_params
        params.permit(
          :call_duration,
          :call_status,
          :date_time,
          :unique_id,
          :agent_id,
          :phone,
          :phone_no,
          :call_start_date_time,
          :session_id,
          :call_type,
          :ncd,
          :comment
        )
      end

    end

  end

end

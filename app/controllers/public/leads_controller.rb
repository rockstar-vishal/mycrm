module Public
  class LeadsController < ::PublicApiController
    def call_in_create
      if params["dispnumber"].blank? && params["caller_id"].blank?
        render json: {status: false, message: "Customer and Enquiry number both are required"}, status: 422
      else
        call_in = CallIn.find_by_number(params["dispnumber"])
        if call_in.blank?
          render json: {status: false, message: "Enquiry number is not correct"}, status: 422 and return
        else
          company = call_in.company
          final_phone = params["caller_id"].gsub("+91", "")
          user_id = call_in.user_id
          from_phone_user_id = company.users.identify_from_phone(leads_with_recording_params[:destination])
          user_id = from_phone_user_id if from_phone_user_id.present?
          lead = company.leads.build(:name=>"--", :mobile=>final_phone,:source_id=> 2, :sub_source=>call_in.source_name, :status_id=>company.new_status_id, :user_id=>user_id, :call_in_id=> call_in.id, :project_id=>call_in.project_id)
          if lead.save
            render json: {status: true, message: "Success"}, status: 201 and return
          else
            render json: {status: false, :message=>"Lead not created", :debug_message=>lead.errors.full_messages.join(","), :data=>{}}, status: 422 and return
          end
        end
      end
    end

    def sarva_create
      if params[:call_in_no].blank? || params[:incoming_no].blank?
        render json: {status: false, message: "Customer and Enquiry number both are required"}, status: 400 and return
      end
      incoming_no = params[:call_in_no].strip
      call_in = CallIn.find_by_number("+#{incoming_no}")
      if call_in.blank?
        render json: {status: false, message: "Call In no. is not correct"}, status: 422 and return
      else
        final_phone = params[:incoming_no].strip.gsub("91", "")
        company = call_in.company
        lead = company.leads.build(:name=>"--", :mobile=>final_phone, :source_id=> 2, :sub_source=>call_in.source_name, :status_id=>company.new_status_id, :user_id=>call_in.user_id, :call_in_id=> call_in.id, :project_id=>call_in.project_id)
        if lead.save
          render json: {status: true, message: "Success"}, status: 201 and return
        else
          render json: {status: false, :message=>"Lead not created", :debug_message=>lead.errors.full_messages.join(",")}, status: 422 and return
        end
      end
    end
  end
end

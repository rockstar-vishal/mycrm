module Public
  class FacebookController < ::PublicApiController
    #before_action :verify_xhub_signature, only: [:create_lead]

    def callback
      if params["hub.mode"] == "subscribe" && params["hub.verify_token"] == CRMConfig.fb_callback_verify_token
        render plain: params["hub.challenge"], status: 200 and return
      else
        render json: {message: "Invalid Data"}, status: 400 and return
      end
    end

    def create_lead
      form_id = leadgen_params[:form_id]
      leadgen_id = leadgen_params[:leadgen_id]
      page_id = leadgen_params[:page_id]
      external_entry = ::Facebook::External.find_by_fbpage_id page_id
      if external_entry.present?
        status, response = HTTPSao.secure_post external_entry.endpoint_url, params.except(:controller, :action).to_json
        if status
          render json: {message: "Success"}, status: 201 and return
        else
          render json: {message: "Failure"}, status: 400 and return
        end
      end
      render json: {:message=>"Lead not created", :debug_message=>"Form ID / Lead ID Empty"}, status: 400 and return if form_id.blank? || leadgen_id.blank?
      company_form = ::Companies::FbForm.find_by_form_no form_id
      fb_page = Companies::FbPage.find_by(page_fbid: page_id)
      company = fb_page.company rescue nil
      fb_ads_id = company.fb_ads_ids.find_by(number: leadgen_params["ad_id"]) rescue nil
      if company_form.present? || fb_ads_id.present?
        if fb_page.present?
          graph = ::Koala::Facebook::API.new(fb_page.access_token)
          begin
            data = graph.get_object(leadgen_id, {fields: "field_data"})["field_data"]
            name = data.detect{|k| k["name"] == "full_name" || k["name"] == "FULL_NAME"}["values"].join(', ') rescue ""
            email = data.detect{|k| k["name"] == "email" || k["name"] == "EMAIL"}["values"].join(', ') rescue ""
            mobile = data.detect{|k| k["name"] == "phone_number" || k["name"] == "PHONE"}["values"].join(', ') rescue ""
            if company_form.present? && company.fb_campaign_enabled && company_form.campaign.present?
              company_form.campaign.projects.each do |project|
                lead = company.leads.build(:name=>name, :email=>email, :mobile=>mobile, :source_id=>::Source::FACEBOOK, :date=>Date.today, :status_id=>company.new_status_id, :project_id=>project.id)
                bindables = data.reject{|k| ["full_name", "email", "phone_number"].include?(k["name"])}
                bind_comment = company_form.bind_comment
                if bind_comment.present? && bindables.present?
                  bindables.each do |bindable|
                    bind_comment = bind_comment.gsub("{{#{bindable['name']}}}", bindable['values'].join(', '))
                  end
                  lead.comment = bind_comment
                end
                if company.is_allowed_field?('customer_type')
                  lead.customer_type = company_form.customer_type
                end
                if company.is_allowed_field?('enquiry_sub_source_id')
                  lead.enquiry_sub_source_id = company_form.enquiry_sub_source_id
                else
                  lead.sub_source = company_form.title
                end
                fb_magic_form_fields = company.magic_fields.where(fb_form_field: true)
                if fb_magic_form_fields.present?
                  fb_magic_form_fields.each do |mf|
                    lead.send("#{mf.name}=", (data.detect{|k| k["name"] == mf.fb_field_name}["values"].join(', ') rescue ""))
                  end
                end
                lead.save
              end
              render json: {message: "Success"}, status: 201 and return
            else
              lead = company.leads.build(:name=>name, :email=>email, :mobile=>mobile, :source_id=>::Source::FACEBOOK, :date=>Date.today, :status_id=>company.new_status_id, :project_id=>company_form&.project_id)
              bindables = data.reject{|k| ["full_name", "email", "phone_number"].include?(k["name"])}
              if company_form.present?
                bind_comment = company_form.bind_comment
                if bind_comment.present? && bindables.present?
                  bindables.each do |bindable|
                    bind_comment = bind_comment.gsub("{{#{bindable['name']}}}", bindable['values'].join(', '))
                  end
                  lead.comment = bind_comment
                end
                if company.is_allowed_field?('customer_type')
                  lead.customer_type = company_form.customer_type
                end
                if company.is_allowed_field?('enquiry_sub_source_id')
                  lead.enquiry_sub_source_id = company_form.enquiry_sub_source_id
                else
                  lead.sub_source = company_form.title
                end
              end
              fb_magic_form_fields = company.magic_fields.where(fb_form_field: true)
              if fb_magic_form_fields.present?
                fb_magic_form_fields.each do |mf|
                  lead.send("#{mf.name}=", (data.detect{|k| k["name"] == mf.fb_field_name}["values"].join(', ') rescue ""))
                end
              end
              if fb_ads_id.present?
                project_id = fb_ads_id.project_id
                if project_id.present?
                  lead.project_id = project_id
                  lead.fb_ads_id = leadgen_params["ad_id"]
                end
              end
              if lead.save
                render json: {message: "Success", :debug_message=>"Lead No: #{lead.reload.lead_no}"}, status: 201 and return
              else
                render json: {:message=>"Lead not created", :debug_message=>lead.errors.full_messages.join(', ')}, status: 422 and return
              end
            end
          rescue Exception => e
            error_message = "#{e.backtrace[0]} --> #{e}"
            render json: {:message=>"Lead not created", :debug_message=>error_message}, status: 422 and return
          end
        else
          render json: {:message=>"Lead not created", :debug_message=>"FB Page not present for #{company_form.title}"}, status: 200 and return
        end
      else
        render json: {:message=>"Lead not created", :debug_message=>"No Mapping for Form ID Found #{form_id}"}, status: 200 and return
      end
    end

    private

      def verify_xhub_signature
        if request.headers["x-hub-signature"].blank? || (Digest::SHA1.hexdigest(CRMConfig.fb_app_secret) != request.headers["x-hub-signature"])
          render json: {message: "Invalid Signature"}, status: 401 and return
        end
      end

      def leadgen_params
        params.require(:entry).first.require(:changes).first.require(:value)
      end
  end
end

module Public
  class CompanyLeadsController < ::PublicApiController
    include ActionController::HttpAuthentication::Token::ControllerMethods
    before_action :find_company
    before_action :set_api_key, only: :create_lead

    def create_lead
      lead = @company.leads.build(lead_params.merge(:source_id=>@api_obj.source_id, :user_id=>@api_obj.user_id, :project_id=>@api_obj.project_id))
      if lead.save
        render json: {message: "Success", data: {lead_no: lead.reload.lead_no}}, status: 201 and return
      else
        render json: {message: "Failed", errors: lead.errors.full_messages.join(', ')}, status: 422 and return
      end
    end

    def create_external_lead
      email=external_lead_params[:email] rescue ""
      phone = external_lead_params[:mobile] rescue ""
      lead = @company.leads.where("((email != '' AND email IS NOT NULL) AND email = ?) OR ((mobile != '' AND mobile IS NOT NULL) AND mobile LIKE ?)", email, "#{phone.last(10) if phone.present?}").last
      if lead.present?
        if lead.update_attributes(external_lead_params.merge(status_id: @company.expected_site_visit&.id))
          render json: {message: "Updated Successfuly", data: {lead_no: lead.reload.lead_no}}, status: 201 and return
        else
          render json: {message: "Failed", errors: lead.errors.full_messages.join(', ')}, status: 422 and return
        end
      else
        lead = @company.leads.build(external_lead_params.merge(status_id: @company.expected_site_visit&.id))
        if lead.save
          render json: {message: "Success", data: {lead_no: lead.reload.lead_no}}, status: 201 and return
        else
          render json: {message: "Failed", errors: lead.errors.full_messages.join(', ')}, status: 422 and return
        end
      end
    end

    def create_leads_all
      source_id = @company.sources.find_id_from_name(params[:source])
      if @company.is_allowed_field?('enquiry_sub_source_id')
        enquiry_sub_source_id = (@company.sub_sources.find_id_from_name(params[:sub_source]) rescue nil)
      else
        sub_source = params[:sub_source]
      end
      project_id = @company.projects.find_id_from_name(params[:project])
      user = @company.users.find_by_email params[:user_email]
      lead = @company.leads.build(lead_params.merge(:source_id=>source_id, :project_id=>project_id, :sub_source=>sub_source, enquiry_sub_source_id: enquiry_sub_source_id))
      mf_names = @company.magic_fields.pluck(:name)
      mf_names.each do |mf_name|
        lead.send("#{mf_name}=", params[mf_name.to_sym])
      end
      lead.user_id = 129 if @company.id == 3
      lead.user_id = user.id if user.present?
      if lead.save
        render json: {message: "Success", data: {lead_no: lead.reload.lead_no}}, status: 200 and return
      else
        render json: {message: "Failed", errors: lead.errors.full_messages.join(', ')}, status: 422 and return
      end
    end

    def create_jd_lead
      source_id = @company.sources.find_id_from_name('Just Dial')
      sub_source = params[:sub_source]
      project_id = @company.projects.find_id_from_name(params[:project]) || @company.default_project&.id
      user = @company.users.find_by_email params[:user_email]
      lead = @company.leads.build(lead_params.merge(:source_id=>source_id, :project_id=>project_id, :sub_source=>sub_source))
      lead.user_id = user.id if user.present?
      if lead.save
        render json: {message: "SUCCESS", data: {lead_no: lead.reload.lead_no}}, status: 200 and return
      else
        render json: {message: "Failed", errors: lead.errors.full_messages.join(', ')}, status: 422 and return
      end
    end

    def google_ads
      project = @company.projects.find_by_uuid(params["google_key"])
      render json: {message: ""}, status: 400 and return if project.blank?
      data = params["user_column_data"]
      full_name = data.detect{|k| k["column_id"] == "FULL_NAME"}["string_value"]
      email = data.detect{|k| k["column_id"] == "EMAIL"}["string_value"]
      phone = data.detect{|k| k["column_id"] == "PHONE_NUMBER"}["string_value"]
      gclick_id = params["gcl_id"]
      this_comment = []
      other_data = data.reject{|k| ['FULL_NAME', 'EMAIL', 'PHONE_NUMBER'].include?(k["column_id"])}
      lead = @company.leads.new(name: full_name, email: email, mobile: phone,  source_id: ::Source::GOOGLE_ADS, :status_id=> @company.new_status, project_id: project.id, gclick_id: gclick_id)
      if other_data.present?
        other_data.each do |od|
          this_comment << "#{od['column_name'] || od['column_id'].humanize}: #{od['string_value']}"
        end
        lead.comment = this_comment.join(' | ')
      end
      if lead.save
        render json: {message: "Success"}, status: 200 and return
      else
        render json: {:message=>"Lead not created #{lead.errors.full_messages.join(', ')}"}, status: 422 and return
      end
    end

    def magicbricks
      render json: {message: "Project ID not sent"}, status: 400 and return if params[:project_id].blank?
      project = @company.projects.find_by_mb_token(params[:project_id]) rescue nil
      if project.blank?
        project = @company.projects.where("property_codes &&  ?", "{#{params[:project_id]}}").last rescue nil
      end
      render json: {message: "Project ID Invalid"}, status: 400 and return if project.blank?
      lead = @company.leads.build(lead_params.merge(:source_id=>::Source::MAGICBRICKS, :project_id=>project.id))
      if lead.save
        render json: {message: "Success", data: {lead_no: lead.reload.lead_no}}, status: 201 and return
      else
        render json: {message: "Failed", errors: lead.errors.full_messages.join(', ')}, status: 422 and return
      end
    end

    def nine_nine_acres
      render json: {message: "Project ID not sent"}, status: 400 and return if params[:project_id].blank?
      project = @company.projects.find_by_nine_token params[:project_id]
      if project.blank?
        project = @company.projects.where("property_codes &&  ?", "{#{params[:project_id]}}").last rescue nil
      end
      render json: {message: "Project ID Invalid"}, status: 400 and return if project.blank?
      lead = @company.leads.build(lead_params.merge(:source_id=>::Source::NINE_NINE_ACRES, :project_id=>project.id))
      if lead.save
        render json: {message: "Success", data: {lead_no: lead.reload.lead_no}}, status: 201 and return
      else
        render json: {message: "Failed", errors: lead.errors.full_messages.join(', ')}, status: 422 and return
      end
    end

    def housing
      project = @company.projects.find_by(housing_token: params[:project_id])
      if project.blank?
        project = @company.projects.where("property_codes &&  ?", "{#{params[:project_id]}}").last rescue nil
      end
      render json: {message: "Project ID Invalid"}, status: 400 and return if project.blank?
      lead = @company.leads.build(lead_params.merge(:source_id=>::Source::HOUSING, :status_id=>@company.new_status_id, :project_id=>project.id))
      if lead.save
        render json: {message: "Success", data: {lead_no: lead.reload.lead_no}}, status: 201 and return
      else
        render json: {message: "Failed", errors: lead.errors.full_messages.join(', ')}, status: 422 and return
      end
    end

    def settings
      projects = @company.projects.select("projects.id, projects.name as text").as_json
      sources = @company.sources.reorder(nil).order(:name).select("sources.id, sources.name as text").as_json
      cp_sources = @company.cp_sources&.ids rescue nil
      brokers = @company.brokers.select("brokers.id, brokers.name as text").as_json
      cities = City.all.select("cities.id, cities.name as text").as_json
      render json: {projects: projects, sources: sources, cp_sources: cp_sources, brokers: brokers, cities: cities}
    end

    private

    def lead_params
      params.permit(:name, :email, :mobile, :comment)
    end

    def external_lead_params
      params.permit(:name, :email, :mobile, :project_id, :source_id, :city_id, :comment, :tentative_visit_planned, :broker_id)
    end

    def find_company
      @company = (::Company.find_by_uuid params[:uuid]) rescue nil
      render json: {message: "Invalid Company ID"}, status: 400 and return if @company.blank?
    end

    def set_api_key
      find_api_obj || render_invalid
    end

    def render_invalid
      render json: {message: 'Invalid API Key'}, status: 401 and return
    end

    def find_api_obj
      authenticate_with_http_token do |token, options|
        @api_obj = @company.api_keys.find_by_key token
        return true if @api_obj.present?
        return false
      end
    end
  end
end

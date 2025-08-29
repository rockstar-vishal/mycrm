module Api
  module MobileCrm
    class SiteVisitInformationsController < ::Api::MobileCrmController
      before_action :authenticate, except: [:settings, :create_lead, :fetch_broker, :create_broker, :fetch_lead]
      before_action :find_company, :set_api_key, only: [:create_lead, :settings, :fetch_broker, :create_broker, :fetch_lead]
      before_action :set_leads, only: [:create_lead, :fetch_lead]

      def create_lead
        email = lead_params[:email] rescue ""
        phone = lead_params[:mobile] rescue ""
        dead_status_ids = @company.dead_status_ids
        if lead_params[:user_id].present?
          user = @company.users.find_by(id: lead_params[:user_id]) rescue nil
        else
          user=@company.users_projects.find_by_project_id(lead_params[:project_id]).user rescue nil
        end
        @lead = @leads.where("((email != '' AND email IS NOT NULL) AND email = ?) OR ((mobile != '' AND mobile IS NOT NULL) AND RIGHT(mobile, 10) LIKE ?)", email, "#{phone.last(10) if phone.present?}").last
        if @lead.present? && !@company.restrict_sv_form_duplicate_lead_visit
          if @lead.update_attributes(lead_params.merge(:status_id=>@company.site_visit_done&.id))
            create_site_visit
            render json: {status: true, message: "Updated", lead: @lead.reload.as_api_response(:meta_details_with_detail)}, status: 201 and return
          else
            render json: {status: false, message: @lead.errors.full_messages.join(', ')}, status: 422 and return
          end
        else
          @lead = @leads.new
          @lead.assign_attributes(lead_params.merge(:status_id => @company.site_visit_done&.id, user_id: user&.id))
          if @lead.save
            create_site_visit
            render json: {status: true, message: "Success", lead: @lead.as_api_response(:meta_details_with_detail)}, status: 201 and return
          else
            render json: {status: false, message: @lead.errors.full_messages.join(', ')}, status: 422 and return
          end
        end
      end

      def create_broker
        @broker = @company.brokers.new(broker_params)
        if @broker.save
          render json: {status: true, broker: @broker.as_json(only: [:id, :name, :rera_number, :firm_name, :mobile, :locality, :email])}, status: 201 and return
        else
          render json: {status: false, message: @broker.errors.full_messages.join(', ')}, status: 422 and return
        end
      end

      def settings
        projects = @company.projects.active.select("projects.id, projects.name as text").as_json
        sources = @company.sources.reorder(nil).order(:name).select("sources.id, sources.name as text").as_json
        cp_sources = @company.cp_sources&.ids rescue nil
        digital_sources_ids =  @company.digital_sources&.ids rescue nil
        reference_source_ids = @company.referal_sources&.ids rescue nil
        digital_sub_souces = SubSource.where(name: Lead::DIGITALSUBSOURCES).select("id, name as text").as_json
        brokers = @company.brokers.select("brokers.id, CONCAT (brokers.name, '--', brokers.firm_name) as text, brokers.mobile as contact_number, brokers.rera_number, brokers.locality, brokers.firm_name, brokers.name, brokers.email").as_json
        users=@company.users.select("users.id, users.name as text").as_json
        cities=::City.all.select("cities.id, cities.name as text").as_json
        localities=::Locality.includes(region: [:city]).as_api_response(:details)
        render json: {projects: projects, brokers: brokers, sources: sources, cp_sources_ids: cp_sources, reference_source_ids: reference_source_ids, digital_sources_ids: digital_sources_ids, users: users, cities: cities, localities: localities, digital_sub_souces: digital_sub_souces}, status: 200 and return
      end

      def fetch_broker
        render json: {message: "Require Broker id"}, status: 400 and return if params[:broker_id].blank?
        broker = Broker.find(params[:broker_id])
        details = {firm_name: broker.firm_name, rera_no: broker.rera_number, mobile_no: broker.mobile}
        render json: details, status: 200 and return
      end

      def fetch_lead
        phone = params[:mobile] rescue nil
        lead = @leads.where("project_id IN (?)", params[:project_id]).where("((mobile != '' AND mobile IS NOT NULL) AND mobile LIKE ?)", "#{phone.last(10) if phone.present?}").last
        if lead.present?
          render json: {lead: lead.as_api_response(:meta_details_with_detail)}, status: 200 and return
        else
          render json: {message: "Lead is not present"}, status: 200 and return
        end
      end

      private

      def create_site_visit
        prev_presale_id = (@company.users.calling_executives.find_by(id: params[:lead][:visit_user_id])&.id rescue nil)
        @lead.visits.create(
          date: Time.zone.now.to_date,
          user_id: prev_presale_id
        )
      end

      def find_company
        @company = (::Company.find_by_uuid params[:uuid]) rescue nil
        render json: {message: "Invalid Company ID"}, status: 400 and return if @company.blank?
      end

      def set_leads
        @leads = @company.leads
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

      def lead_params
        magic_fields = (@company.magic_fields.map{|field| field.name.to_sym} rescue [])
        params.require(:lead).permit(
          *magic_fields,
          :name,
          :email,
          :mobile,
          :comment,
          :address,
          :locality_id,
          :city_id,
          :project_id,
          :enquiry_sub_source_id,
          :source_id, :broker_id, :user_id, :referal_name, :referal_mobile, :presale_user_id,
          :visits_attributes=>[:date, :comment]
        )
      end

      def broker_params
        params.require(:broker).permit(:name, :email, :mobile, :firm_name, :locality, :rera_number, :rm_id, :other_contacts)
      end

    end
  end
end
class CompaniesController < ApplicationController
  before_action :set_company, only: [:show, :edit, :update, :destroy, :fb_pages, :prepare_import_fb_pages, :import_fb_pages, :broker_form]
  before_action :build_configuration_attributes, only: :edit

  respond_to :html

  PER_PAGE = 20

  def index
    @companies = Company.all
    respond_to do |format|
      format.html do
        @companies = @companies.paginate(:page => params[:page], :per_page => PER_PAGE)
      end
      format.csv do
        send_data @companies.to_csv({}), filename: "company_details_#{Date.today.to_s}.csv"
      end
    end
  end

  def fb_pages
    @fb_pages = @company.fb_pages
  end

  def prepare_import_fb_pages

  end

  def import_fb_pages
    if params[:lead_file].present?
      file = params[:lead_file].tempfile
      @success=[]
      @errors=[]
      CSV.foreach(file, {:headers=>:first_row, :encoding=> "iso-8859-1:utf-8"}) do |row|
        arr_row = row.to_a
        token = arr_row.first.last
        title = row["name"]
        page_fbid = row["id"]
        begin
          extend_res = FbSao.extend_token(token).last
          if extend_res["error"].present?
            @errors << {name: title, error: extend_res["error"]}
          else
            if extend_res['access_token'].present?
              extended_token = extend_res['access_token']
              fb_page = @company.fb_pages.build(title: title, page_fbid: page_fbid, access_token: extended_token)
              if fb_page.save
                @success << "#{title} Created"
              else
                @errors << {name: title, error: fb_page.errors.full_messages.join(', ')}
              end
            end
          end
        rescue Exception => e
          error_message = "#{e.backtrace[0]} --> #{e}"
          @errors << {:name=>title, :message=>error_message}
        end
      end
    end
  end

  def show
    render_modal('show', {:class=>'right'})
  end

  def new
    @company = Company.new
    build_configuration_attributes
  end

  def edit
  end

  def create
    @company = Company.new(company_params)
    if @company.save
      flash[:notice] = "Company Created Successfully"
      redirect_to companies_path
    else
      render 'new'
    end
  end

  def update
    if @company.update_attributes(company_params)
      flash[:notice] = "Company Updated Successfully"
      redirect_to companies_path
    else
      render 'edit'
    end
  end

  def destroy
    @company.destroy
    respond_with(@company)
  end

  def broker_form
    @company.build_broker_configuration if @company.broker_configuration.blank?
  end

  private


    def build_configuration_attributes
      @company.build_push_notification_setting if @company.push_notification_setting.blank?
      @company.build_exotel_integration if @company.exotel_integration.blank?
      @company.build_mcube_integration if @company.mcube_integration.blank?
      @company.build_sms_integration if @company.sms_integration.blank?
      @company.build_mailchimp_integration if @company.mailchimp_integration.blank?
      @company.build_setting if @company.setting.blank?
    end

    def set_company
      @company = Company.find(params[:id])
    end

    def company_params
      params.require(:company).permit(
        :name,
        :description,
        :domain,
        :mobile_domain,
        :postsale_url,
        :sms_mask,
        :expected_site_visit_id,
        :site_visit_done_id,
        :booking_done_id,
        :new_status_id,
        :logo,
        :icon,
        :favicon,
        :default_from_email,
        :rejection_reasons,
        :requirement,
        :remove_closed,
        :round_robin_enabled,
        hot_status_ids: [],
        dead_status_ids: [],
        token_status_ids: [],
        popup_fields: [],
        allowed_fields: [],
        index_fields: [],
        visits_allowed_fields: [],
        status_ids: [],
        source_ids: [],
        events: [],
        required_fields: [],
        reasons_attributes: [:id, :_destroy, :reason, :active],
        role_statuses_attributes: [
          :id,
          :role_id,
          :_destroy,
          status_ids: []
        ],
        broker_configuration_attributes: [
        :id,
        {
          required_fields: [],
        }],
        setting_attributes: [
          :id,
          :can_show_lead_phone,
          :global_validation,
          :hide_next_call_date,
          :project_wise_round_robin,
          :can_assign_all_users,
          :call_response_report,
          :biz_integration_enable,
          :client_integration_enable,
          :broker_integration_enable,
          :enable_email_action,
          :enable_whatsapp_action,
          :enable_lead_tracking,
          :enable_callerdesk_sid,
          :enable_presale_user_visits_report,
          :czentrixcloud_enable,
          :visit_filter_enable,
          :secondary_level_round_robin,
          :back_dated_ncd_allowed,
          :edit_profile_not_allowed,
          :enable_lead_direct_edit,
          :enable_call_center_dashboard,
          :default_lead_user_enable,
          :enable_broker_management,
          :hide_lead_mobile_for_executive,
          :can_send_lead_assignment_mail,
          :way_to_voice_enabled,
          :enable_executive_export_leads,
          :set_svp_default_7_days,
          :enable_booking_done_fields,
          :enable_executive_to_assign_users,
          :enable_country_in_project,
          :enable_cards_on_advance_search,
          :enable_advance_visits,
          :enable_site_visit_planned_tracker,
          :enable_ncd_sort_nulls_last,
          :set_ncd_non_mandatory_for_booked_status,
          :enable_meeting_executives,
          :can_clone_lead,
          :can_add_users,
          :enable_lead_log_export,
          :fb_campaign_enabled,
          :managerwise_closing_executive_active,
          :inventory_integration_enable,
          :restrict_sv_form_duplicate_lead_visit,
          :can_delete_users,
          :open_closed_lead_enabled,
          :mobicomm_sms_service_enabled,
          :is_sv_project_enabled,
          :enable_source
        ],
        magic_fields_attributes: [
          :id,
          :name,
          :pretty_name,
          :datatype,
          :is_select_list,
          :is_required,
          :type_scoped,
          :_destroy,
          :items,
          :is_indexed_field,
          :is_popup_field,
          :fb_form_field,
          :fb_field_name
        ],
        push_notification_setting_attributes: [
          :token,
          :project_key,
          :is_active,
          :id,
          :_destroy
        ],
        mcube_groups_attributes: [
          :id,
          :number,
          :group_name,
          :is_active,
          :_destroy
        ],
        exotel_integration_attributes: [
          :id,
          :title,
          :active,
          :integration_key,
          :token,
          :sid,
          :callback_url
        ],
        mailchimp_integration_attributes: [
          :id,
          :title,
          :active,
          :integration_key,
          :token,
        ],
        mcube_integration_attributes: [
          :id,
          :title,
          :active,
          :integration_key,
          :callback_url
        ],
        sms_integration_attributes: [
          :id,
          :title,
          :active,
          :integration_key,
          :url
        ],
        custom_labels_attributes: [
          :id,
          :key,
          :default_value,
          :custom_value,
          :_destroy
        ],
        company_stages_attributes: [
          :id,
          :stage_id,
          :_destroy,
          company_stage_statuses_attributes: [
            :id,
            :status_id,
            :_destroy
          ]
        ]
      )
    end
end

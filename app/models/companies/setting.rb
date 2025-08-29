class Companies::Setting < ActiveRecord::Base
  belongs_to :company

  SETTING_BOOLEAN_FIELDS = [
    :can_assign_all_users,
    :can_show_lead_phone,
    :global_validation,
    :hide_next_call_date,
    :project_wise_round_robin,
    :call_response_report,
    :biz_integration_enable,
    :inventory_integration_enable,
    :client_integration_enable,
    :broker_integration_enable,
    :enable_whatsapp_action,
    :enable_email_action,
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
    :set_ncd_non_mandatory_for_booked_status,
    :enable_ncd_sort_nulls_last,
    :enable_site_visit_planned_tracker,
    :enable_executive_export_leads,
    :set_svp_default_7_days,
    :enable_booking_done_fields,
    :enable_executive_to_assign_users,
    :enable_country_in_project,
    :enable_advance_visits,
    :enable_cards_on_advance_search,
    :enable_meeting_executives,
    :can_clone_lead,
    :open_closed_lead_enabled,
    :can_add_users,
    :enable_lead_log_export,
    :fb_campaign_enabled,
    :managerwise_closing_executive_active,
    :postsales_integration_active,
    :can_delete_users,
    :restrict_sv_form_duplicate_lead_visit,
    :mobicomm_sms_service_enabled,
    :is_sv_project_enabled,
    :enable_source
  ]

  def default_fields_values
    self.setting_data || {}
  end

  SETTING_BOOLEAN_FIELDS.each do |method|
    define_method("#{method}=") do |val|
      if ["true", "false", "t", "f", "0", "1"].include?(val)
        val = ActiveRecord::ConnectionAdapters::Column.value_to_boolean(val)
      end
      self.setting_data_will_change!
      self.setting_data = (self.setting_data || {}).merge!({"#{method}" => val})
    end
    define_method("#{method}") do
      default_fields_values.dig("#{method}")
    end
  end

end

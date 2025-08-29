module AccessControl
  class << self

    def route_is_accessible_sysad params
      controller, action = params[:controller], params[:action]
      return true if ["companies", "dashboards", "devise/sessions", 'sources', 'users', 'statuses', 'cities', 'regions', 'localities', 'call_ins', 'stages', 'countries'].include?(controller)
    end

    def route_is_accessible_superadmin params
      return true if self.route_is_accessible_manager params
      controller, action = params[:controller], params[:action]
      return true if ["sub_sources","projects", 'notification_templates', 'campaigns', 'companies/api_keys', 'companies/fb_pages', 'companies/fb_forms', 'exotel_sids','mcube_sids', 'brokers', 'cities' ].include?(controller)
      if controller == "users"
        user = params[:user]
        return true unless (['new', 'create'].include?(action) && !user.company.can_add_users)
      end
      if controller == 'call_ins'
        return true unless ['new', 'create'].include?(action)
      end
      return false
    end

    def route_is_accessible_manager params
      return true if self.route_is_accessible_executive params
      controller, action = params[:controller], params[:action]
      return false
    end

    def route_is_accessible_executive params
      controller, action = params[:controller], params[:action]
      return true if ["leads", "loans", "reports", "dashboards", "users/search_histories", "devise/sessions", "leads/notifications", 'companies/flats'].include?(controller)
      user = params[:user]
      if controller == "brokers"
        return user.company.setting.present? && user.company.enable_broker_management
      end
      if controller == "users"
        return (["edit_profile", "update_profile"].include?(action))
      end
      return false
    end

    def route_is_accessible_supervisor params
      controller, action = params[:controller], params[:action]
      return true if ["onsite_leads", "devise/sessions"].include?(controller)
      if controller == 'leads'
        return true if ['update'].include?(action)
      end
      return false
    end

  end
end

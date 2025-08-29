Rails.application.routes.draw do
  devise_for :users
  devise_scope :user do
    authenticated :user do
      root 'dashboards#index', as: :root
    end
    unauthenticated do
      root 'devise/sessions#new', as: :unauthenticated_root
    end
  end
  resources :dashboards, only: [:index] do
    collection do
      get 'statistics'
      get 'trend_report'
      get 'lease_data'
    end
  end
  resources :loans, only: [:index, :edit, :update] do
    collection do
      get :loan_counts
    end
  end
  resources :leads do
    member do
      get :histories
      get "visits/new", to: :new_visit, as: :new_visit
      post "visits/create", to: :create_visit, as: :create_visit
      get "visits/:visit_id/edit", to: :edit_visit, as: :edit_visit
      delete "visits/:visit_id", to: :delete_visit, as: :delete_visit
      post :make_call
      get :new_loan
      get :copy
      post :copy, to: :perform_copy
      post :create_loan
      get :localities
    end
    collection do
      get ":status_id/stages", to: :stages
      get :import
      get 'calender_view', as: :calender_view, to: :calender_view
      post :import, to: :perform_import
      put :bulk_action
      get :export
      get :prepare_bulk_update
      get :call_logs
      get :outbound_logs
      get :dead_or_recycle
      put :import_bulk_update
      get :lead_counts
    end
  end
  resources :onsite_leads
  namespace :leads do
    resources :notifications, only: [] do
      collection do
        get ':lead_id/send_sms', to: :send_sms, as: :send_sms
        get ':lead_id/template_detail/:template_id', to: :template_detail, as: 'template_detail'
        post ':template_id/:lead_id/update_template_detail', to: :update_template_detail, as: 'update_template_detail'
        post ':lead_id/shoot_notification/:notification_id', to: :shoot_notification, as: 'shoot_notification'

        get ':lead_id/send_email', to: :send_email, as: :send_email
        post ':lead_id/shoot_email', to: :shoot_email, as: :shoot_email
      end
    end
  end
  resources :notification_templates ,param: :uuid
  resources :campaigns ,param: :uuid
  resources :call_ins, param: :uuid
  resources :stages, param: :uuid
  resources :projects, param: :uuid
  resources :exotel_sids, param: :uuid do
    collection do
      get :statistics
    end
  end
  resources :mcube_sids, param: :uuid
  resources :brokers, param: :uuid
  resources :statuses
  resources :countries
  resources :cities
  resources :regions
  resources :localities
  resources :sources
  resources :sub_sources, param: :uuid
  resources :roles, except: [:new, :edit]
  namespace :users do
    resources :search_histories, only: [:index, :destroy]
  end
  resources :users, param: :uuid do
    collection do
      get :edit_profile
      patch :update_profile
      get :edit_user_config
      put :round_robin, to: :enable_round_robin
      delete :round_robin, to: :disable_round_robin
    end
  end
  namespace :companies do
    resources :flats do
      collection do
        get :fetch_biz_flats
        get :fetch_projects
      end
      member do
        get :fetch_buildings
        get :flat_block_modal
        post :block_flat
        get :fetch_building_flats
      end
    end
    resources :api_keys, param: :uuid
    resources :fb_pages, param: :fb_id do
      member do
        get :fb_forms
        get :new_fb_form
      end
    end
    resources :fb_forms, param: :form_no
  end
  resources :companies do
    member do
      get :fb_pages
      get "fb_pages/import", to: :prepare_import_fb_pages
      post "fb_pages/import", to: :import_fb_pages
      get :broker_form
    end
  end
  get :configurations, :to => 'leads#configurations', path: '/configurations'
  namespace :reports do
    get :source
    get :projects
    get :campaigns
    get "campaign/:campaign_uuid", to: :campaign_detail, as: :campaign_detail
    get :backlog
    get :dead
    get :leads
    get :visits
    get :presale_visits
    get :site_visit_userwise
    get :closing_executives
    get :trends
    get :activity
    get :site_visit_planned_tracker
    get :site_visit_planned
    get :user_call_reponse_report
    get :scheduled_site_visits
    get :call_report
    get ':lead_id/scheduled_site_visits_detail', to: :scheduled_site_visits_detail, as: :scheduled_site_visits_detail
    get ":user_id/activity", to: :activity_details, as: :activity_details
  end

  namespace :api do
    post :login
    delete :logout
    namespace :mobile_crm do
      get :projects
      get :settings
      get :status_wise_stage
      get :dashboard
      get 'suggest/users', to: :suggest_users
      get 'suggest/projects', to: :suggest_projects
      get 'suggest/managers', to: :suggest_managers
      resources :leads, only: [:index, :show, :update, :create], param: :uuid do
        collection do
          get :magic_fields
          post :make_call
          get :settings
        end
        member do
          delete "visits/:visit_id", to: :delete_visit
          post :log_call_attempt
          get :histories
        end
      end
      resources :saved_searches, only: [:index, :create, :destroy]
      post "companies/:uuid/leads", to: "site_visit_informations#create_lead"
      get "companies/:uuid/settings", to: "site_visit_informations#settings"
      get "companies/:uuid/broker", to: "site_visit_informations#fetch_broker"
      post "companies/:uuid/brokers", to: "site_visit_informations#create_broker"
      get "companies/:uuid/fetch_leads", to: "site_visit_informations#fetch_lead"
      scope 'companies/:uuid' do
        namespace :sv_apps do
          resources :otps, only: :create do
            collection do
              get :validate
            end
          end
        end
      end
    end
    namespace :third_party_service do
      resources :exotels, only: [] do
        collection do
          post :callback
          get :incoming_call_back
          get :incoming_connection
          get :incoming_call
          get :marketing_incoming_call
          get :notify_users
          get :marking_call_callback
        end
      end
      resources :mcubes, only: [] do
        collection do
          post :callback
          post :incoming_call
          post :ctc_ic
          post :hangup
        end
      end
      resources :caller_desk, only: [] do
        collection do
          get :hangup
        end
      end
      resources :knowlarities, only: [] do
        collection do
          post ':uuid/incoming_call', to: "knowlarities#incoming_call"
        end
      end
      resources :czentrixcloud, only: [] do
        collection do
          post :callback
          post :incoming_call_connect
          post :incoming_call_disconnect
          get ':call_id/dialwhom', to: :dialwhom
        end
      end
      resources :way_voice, only: [] do
        collection do
          post ':uuid/outbound_disconnect', to: "way_voice#outbound_disconnect"
          post ':uuid/incoming_call', to: "way_voice#incoming_call"

        end
      end
    end
  end

  namespace :public do
    post "companies/:uuid/leads", to: "company_leads#create_lead"
    post "companies/:uuid/jd_leads", to: "company_leads#create_jd_lead"
    post "companies/:uuid/leads-all", to: "company_leads#create_leads_all"
    post "companies/:uuid/create_external_lead", to: "company_leads#create_external_lead"
    get "companies/:uuid/settings", to: "company_leads#settings"
    post "companies/:uuid/google_ads", to: "company_leads#google_ads"
    match "companies/:uuid/magicbricks", to: "company_leads#magicbricks", via: [:get, :post]
    post "companies/:uuid/nine_nine_acres", to: "company_leads#nine_nine_acres"
    post "companies/:uuid/telecalling/leads", to: "telecalling#create_lead"
    post "companies/:uuid/housing", to: "company_leads#housing"
    namespace :leads do
      post "call-in/create", to: :call_in_create
      get "call_in/sarva/create", to: :sarva_create
    end
    namespace :facebook do
      get :leads, to: :callback
      post :leads, to: :create_lead
    end
  end

  mount Resque::Server.new, :at => "/resque"
end

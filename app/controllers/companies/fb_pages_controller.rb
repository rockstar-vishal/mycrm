class Companies::FbPagesController < ApplicationController
  before_action :set_fb_pages
  before_action :set_fb_page, only: [:fb_forms, :new_fb_form]

  def index

  end

  def create
    @errors = []
    token = params["access_token"]
    name = params["name"]
    page_fbid = params["id"]
    if token.present?
      extend_res = FbSao.extend_token(token).last
      if extend_res["error"].present?
        @errors << {name: name, error: extend_res["error"]}
      else
        if extend_res['access_token'].present?
          extended_token = extend_res['access_token']
          current_fb_pages = current_user.company.fb_pages
          if current_fb_pages.find_by_page_fbid(page_fbid).present?
            fb_page = current_fb_pages.find_by_page_fbid(page_fbid)
            fb_page.access_token = extended_token
          else
            fb_page = current_fb_pages.build(title: name, page_fbid: page_fbid, access_token: extended_token)
          end
          unless fb_page.save
            @errors << {name: name, error: fb_page.errors.full_messages.join(', ')}
          end
        end
      end
    else
      @errors << "Token Not present for #{name}"
    end
    render json: {error_message: @errors.present? ? @errors.join(', ') : "None" }, status: 200 and return
  end

  def fb_forms
    success, @fb_forms_api = @fb_page.leadgen_forms
    if success
      @fb_forms_db = @fb_page.fb_forms.joins{project}.select("projects.name as project_name, companies_fb_forms.form_no, companies_fb_forms.bind_comment").as_json
    else
      flash[:notice] = @fb_forms_api
      redirect_to request.referer
    end
  end

  def new_fb_form
    @form_name = "Create Mapping"
    @fb_form = @fb_page.fb_forms.build fb_form_params
    @form_fields = @fb_form.form_fields
    render_modal "fb_form_fields"
  end

  private
    def set_fb_pages
      @fb_pages = current_user.company.fb_pages
    end

    def set_fb_page
      @fb_page =  @fb_pages.find_by_page_fbid params[:fb_id]
    end

    def fb_form_params
      params.permit(:form_no, :title)
    end
end
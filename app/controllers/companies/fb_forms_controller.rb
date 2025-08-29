class Companies::FbFormsController < ApplicationController
  before_action :set_fb_forms
  before_action :set_fb_page, only: [:create]

  before_action :set_fb_form, only: [:destroy, :edit, :update]

  def create
    @fb_form = @fb_forms.build(fb_forms_params)
    @fb_form.fb_page_id = @fb_page.id
    if @fb_form.save
      flash[:notice] = "Form Mapped Successfully"
    else
      flash[:error] = "Cannot create Mapping - #{@fb_form.errors.full_messages.join(', ')}"
    end
    redirect_to fb_forms_companies_fb_page_path(@fb_form.fb_page.page_fbid) and return
  end

  def edit
    @form_name = "Edit Mapping"
    @form_fields = @fb_form.form_fields
    render_modal "companies/fb_pages/fb_form_fields"
  end

  def update
    if @fb_form.update_attributes(update_form_params)
      flash[:notice] = "Updated Successfully"
    else
      flash[:error] = "Cannot Update Mapping - #{@fb_form.errors.full_messages.join(', ')}"
    end
    redirect_to fb_forms_companies_fb_page_path(@fb_form.fb_page.page_fbid) and return
  end

  def destroy
    if @fb_form.destroy
      flash[:notice] = "Mapping removed Successfully"
    else
      flash[:error] = "Cannot remove Mapping - #{@fb_form.errors.full_messages.join(', ')}"
    end
    redirect_to request.referer and return
  end

  private
    def set_fb_forms
      @fb_forms = current_user.company.fb_forms
    end

    def set_fb_page
      @fb_page = current_user.company.fb_pages.find_by_page_fbid params[:companies_fb_form][:fb_id] rescue nil
      render json: {message: "Failed"}, status: 400 and return if @fb_page.blank?
    end

    def set_fb_form
      @fb_form = @fb_forms.find_by_form_no params[:form_no]
    end

    def fb_forms_params
      params.require(:companies_fb_form).permit(:project_id, :form_no, :title, :bind_comment, :enquiry_sub_source_id, :customer_type, :campaign_id)
    end

    def update_form_params
      params.require(:companies_fb_form).permit(:project_id, :bind_comment, :enquiry_sub_source_id, :campaign_id)
    end
end

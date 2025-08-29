class UserMailer < ActionMailer::Base
  add_template_helper(ApplicationHelper)

  def share_lead_details_on_email(user, email_lists, leads, mail_params)
    @subject = mail_params[:subject]
    @message = mail_params[:message]
    @leads = leads
    @current_user = user
    if Rails.env.production?
      @email_lists = email_lists
      reply_to_and_cc_email = @current_user.email
    else
      @email_lists = ""
      reply_to_and_cc_email = ""
    end
    mail(
      from: user.company.default_from_email,
      to: @email_lists,
      cc: reply_to_and_cc_email,
      reply_to: reply_to_and_cc_email,
      subject: "#{@subject}"
    )
  end

  def share_project_information_on_email(email)
    @lead = email.receiver
    @current_user = email.sender
    subject = email.subject
    @message = email.body
    if Rails.env.production?
      email_lists = email.sender.email
      reply_to_and_cc_email = email.cc_emails.joins(',')
    else
      email_lists = ""
      reply_to_and_cc_email = ""
    end
    mail(
      from: @current_user.company.default_from_email,
      to: email_lists,
      cc: reply_to_and_cc_email,
      subject: "#{subject}"
    )
  end

end
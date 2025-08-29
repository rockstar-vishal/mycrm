module ApplicationHelper

  def flash_messages
    flash.each do |msg_type, message|
      concat(content_tag(:div, message, id: 'flash', class: "alert alert-#{bootstrap_class_for(msg_type)} alert-dismissible text-center", role: 'alert') do
        concat(content_tag(:button, class: 'close', data: { dismiss: 'alert' }) do
          concat content_tag(:span, '&times;'.html_safe, 'aria-hidden' => true)
          concat content_tag(:span, 'Close', class: 'sr-only')
        end)
        concat message
      end)
    end
    nil
  end

  def bootstrap_class_for flash_type
    { success: "alert-success", error: "alert-danger", alert: "alert-warning", notice: "alert-info" }[flash_type] || flash_type.to_s
  end

  def report_tab_selected
    ['reports'].include?(params[:controller]) ? 'menu-open' : ''
  end

  def find_class(source)
    if source.website?
      'success'
    elsif source.incoming_call?
      'danger'
    else
      'warning'
    end
  end

  def seconds_to_time(seconds)
    [(seconds / 3600).to_i, (seconds / 60 % 60).to_i, (seconds % 60).to_i].map { |t| t.to_s.rjust(2,'0') }.join(':')
  end


end
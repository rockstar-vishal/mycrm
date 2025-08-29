class Api::ThirdPartyService::McubesController < PublicApiController

  before_action :find_company, except: [:callback]

  def callback
    @call_log = Leads::CallLog.find_by(sid: mcube_params[:callid])
    if @call_log.update(
      start_time: Time.zone.parse(mcube_params[:starttime]),
      end_time: (Time.zone.parse(mcube_params[:endtime]) rescue nil),
      recording_url: mcube_params[:filename],
      duration: mcube_params[:answeredtime],
      status: mcube_params[:status]
    )
      render :json=>{:status=>"Success"}
    else
      render :json=>{:status=>"Failure"}
    end
  end

  def ctc_ic
    @user = @company.users.active.find_by(mobile: mcube_params[:empnumber])
    @lead = @company.leads.find_by(mobile: mcube_params[:callfrom])
    unless @lead.present?
      @lead = @company.leads.build(
        name: mcube_params[:callername].present? ? mcube_params[:callername] :  '--',
        email: mcube_params[:caller_email],
        :mobile=> mcube_params[:callfrom],
        :source_id=> 2,
        :status_id=>@company.new_status_id,
        :project_id=> @company.default_project&.id,
        user_id: @user&.id
      )
    end
    if @lead.save
      @lead.call_logs.where(sid: mcube_params[:callid]).each{|cl| cl.status=="CONNECTING" && cl.update_attribute(:status, 'NOANSWER')}
      call_logs = @lead.call_logs.build(
        caller: 'Lead',
        direction: 'incoming',
        sid: mcube_params[:callid],
        start_time: mcube_params[:starttime],
        end_time: (Time.zone.parse(mcube_params[:endtime]) rescue nil),
        to_number: mcube_params[:callto],
        from_number: @lead.mobile,
        status: mcube_params[:dialstatus],
        duration: mcube_params[:answeredtime],
        user_id: @lead.user_id,
        recording_url: "https://mcube.vmctechnologies.com/sounds/#{mcube_params[:filename]}",
        third_party_id: 'mcube',
        phone_number_sid: mcube_params[:landingnumber],
        call_type: 'inbound'
      )
      call_logs.save
    else
      render json: {status: false, :message=>"Lead not created", :debug_message=>@lead.errors.full_messages.join(","), :data=>{}}, status: 422 and return
    end
  end

  def incoming_call
    @user = @company.users.active.find_by(email: mcube_params[:empemail]&.downcase) || @company.users.active.superadmins.first
    @lead = @company.leads.find_by(mobile: mcube_params[:callfrom])
    mcube_sid = @company.mcube_sids.where(number: mcube_params[:landingnumber]).last
    project = mcube_sid&.project&.id
    if @lead.present?
      @lead.update_attributes(project_id: project || @company.default_project&.id)
    else
      @lead = @company.leads.build(
        name: mcube_params[:callername].present? ? mcube_params[:callername] :  '--',
        email: mcube_params[:caller_email],
        :mobile=> mcube_params[:callfrom],
        :source_id=> mcube_sid.source_id || 2,
        :status_id=>@company.new_status_id,
        :user_id=>@user.id,
        :project_id=> project || @company.default_project&.id
      )
    end
    if @lead.save
      @lead.call_logs.where(sid: mcube_params[:callid]).each{|cl| cl.status=="CONNECTING" && cl.update_attribute(:status, 'NOANSWER')}
      call_logs = @lead.call_logs.build(
        caller: 'Lead',
        direction: 'incoming',
        sid: mcube_params[:callid],
        start_time: mcube_params[:starttime],
        to_number: mcube_params[:callto],
        from_number: @lead.mobile,
        status: mcube_params[:dialstatus],
        third_party_id: 'mcube',
        phone_number_sid: mcube_params[:landingnumber]
      )
      call_logs.save
    else
      render json: {status: false, :message=>"Lead not created", :debug_message=>@lead.errors.full_messages.join(","), :data=>{}}, status: 422 and return
    end
  end

  def hangup
    @call_log = Leads::CallLog.where(sid: mcube_params[:callid]).last
    @user = @company.users.active.find_by(email: mcube_params[:empemail]) || @company.users.active.superadmins.first
    @lead = @call_log.lead
    if @call_log.update(
      user_id: @user.id,
      end_time: mcube_params[:endtime],
      recording_url: "https://mcube.vmctechnologies.com/sounds/#{mcube_params[:filename]}",
      status: mcube_params[:dialstatus],
      duration: mcube_params[:answeredtime],
      call_type: 'inbound'
    )
      if @lead.present? && Leads::CallLog::ANSWERED_STATUS.include?(@call_log.status) && !@lead.is_repeated_call?
        @lead.update_attribute(:user_id, @user.id)
      end
      render :json=>{:status=>"Success"}
    else
      render :json=>{:status=>"Failure"}
    end
  end

  private

  def find_company
    @company = Company.joins(:mcube_groups).where(mcube_groups: {number: mcube_params[:landingnumber]&.last(10), is_active: true}).first
    render json: {status: false, message: "Invalid"}, status: 404 and return if @company.blank?
  end

  def mcube_params
    JSON.parse(params["data"]).symbolize_keys
  end

end

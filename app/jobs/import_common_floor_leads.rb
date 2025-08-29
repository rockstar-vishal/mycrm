class ImportCommonFloorLeads
  @queue = :import_common_floor_leads
  @status_update_logger = Logger.new('log/import_common_floor_leads.log')

  def self.perform
    start_date = Date.today.strftime('%Y%m%d')
    end_date = Date.today.strftime('%Y%m%d')
    @status_update_logger.info("stared at #{Time.zone.now}")
    errors = []
    begin
      current_time = Time.zone.now.to_i
      ::Companies::Integration.for_common_floor.find_each do |integration|
        company = integration.company
        key = integration.integration_key
        secret = integration.token
        url = "https://www.commonfloor.com/agent/pull-leads/v1?id=#{key}&key=#{secret}&start=#{start_date}&end=#{end_date}&format=json"
        response = RestClient.post(url, {})
        response = JSON.parse(response)
        project_id = company.default_project.id
        source_id = company.sources.find_id_from_name('Common floor')
        response.each do |response_hash|
          date = Time.zone.parse(response_hash["shared_on"]).to_date rescue ""
          name = response_hash["contact_name"]
          email = response_hash["contact_email"]
          mobile = response_hash["contact_mobile"]
          comment = response_hash["details"]
          city_id = City.find_id_from_name(response_hash['city'])
          budget = response_hash["maximum_budget"]
          lead = company.leads.build(:name=>name, :email=>email, :mobile=>mobile, :source_id=>source_id, :date=>date, :status_id=>company.new_status_id, :project_id=>project_id, budget: budget, city_id: city_id, comment: comment)
          lead.save
        end
      end
    rescue Exception => e
      error_message = "#{e.backtrace[0]} --> #{e}"
      errors << {message: error_message}
    end
    @status_update_logger.info("result for #{Time.zone.now} - #{errors}")
  end

end
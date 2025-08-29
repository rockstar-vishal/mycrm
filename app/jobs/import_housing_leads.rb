class ImportHousingLeads
  require 'uri'
  require 'net/http'
  @queue = :import_housing_leads
  @status_update_logger = Logger.new('log/import_housing_leads.log')

  def self.perform
    start_date = (Time.zone.now - 3.hours)
    end_date = Time.zone.now
    @status_update_logger.info("stared at #{Time.zone.now}")
    errors = []
    begin
      current_time = Time.zone.now.to_i
      ::Companies::Integration.for_housing.find_each do |integration|
        company = integration.company
        encryption_key = integration.data["encryption_key"]
        profile_id = integration.data["profile_id"]
        hash = OpenSSL::HMAC.hexdigest(OpenSSL::Digest.new('sha256'), encryption_key, current_time.to_s)
        url = URI("https://leads.housing.com/api/v0/get-builder-leads?start_date=#{start_date.to_i}&end_date=#{end_date.to_i}&current_time=#{current_time.to_i}&hash=#{hash}&id=#{profile_id}")

        http = Net::HTTP.new(url.host, url.port)
        http.use_ssl = true
        http.verify_mode = OpenSSL::SSL::VERIFY_NONE

        request = Net::HTTP::Get.new(url)

        response = http.request(request)
        if response.kind_of? Net::HTTPSuccess
          response_body = JSON.parse response.body
          (response_body || []).each do |response_hash|
            project = company.projects.find_by_housing_token response_hash["project_id"].to_s
            if project.present?
              date = Time.zone.at response_hash["lead_date"]
              name = response_hash["lead_name"]
              email = response_hash["lead_email"]
              mobile = response_hash["lead_phone"]
              lead = company.leads.build(:name=>name, :email=>email, :mobile=>mobile, :source_id=>::Source::HOUSING, :date=>date.to_date, :status_id=>company.new_status_id, :project_id=>project.id)
              lead.save
            else
              errors << {company: company.id, message: "Mapping not found project id #{response_hash['project_id']}"}
            end
          end
        else
          response_body = JSON.parse response.body
          errors << {company: company.id, message: response_body["message"], code: error_code}
        end
      end
    rescue Exception => e
      error_message = "#{e.backtrace[0]} --> #{e}"
      errors << {message: error_message}
    end
    @status_update_logger.info("result for #{Time.zone.now} - #{errors}")
  end

end
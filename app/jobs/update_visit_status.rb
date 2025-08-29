class UpdateVisitStatus

  @queue = :visit_status_log
  @update_visit_status_logger = Logger.new('log/visit_status_log.log')

  def self.perform
    Company.joins{setting}.where("companies_settings.setting_data ->> 'enable_advance_visits' = ?", 'true').each do |company|
      Leads::Visit.joins{lead}.where(leads: {company_id: company.id}).where("leads_visits.is_visit_executed = ? AND leads_visits.is_postponed = ?  AND leads_visits.is_canceled =?", false, false, false).each do |visit|
        if visit.date < Date.today
          visit.update_attributes(is_canceled: true)
        end
      end
      @update_visit_status_logger.info("Done For Company #{company.id}")
    end
  end
end

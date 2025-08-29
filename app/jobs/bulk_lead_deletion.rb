class BulkLeadDeletion

  @queue = :process_leads_deletion
  @process_deletion_logger = Logger.new('log/process_deletion_logger.log')

  def self.perform
    begin
      company = Company.find(37)
      CustomAudit.where(associated_id: 37).each_slice(1000).to_a.each do |audit|
        audit.map(&:delete)
      end
      @process_deletion_logger.info("Audit Deletion Done --- 1")
      company.leads.each_slice(1000).to_a.each do |leads_batch|
        leads_batch.map(&:destroy)
      end
    rescue Exception => e
      @process_deletion_logger.info("processing Deletion Failed--- 2")
    end
    @process_deletion_logger.info("Deletion Done - 3")
    return true
  end

end


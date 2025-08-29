class CallAttempt < ActiveRecord::Base

  belongs_to :user
  belongs_to :lead


  class << self

    def advance_search(params)
      call_attempts = all
      if params[:project_ids].present?
        call_attempts = call_attempts.joins{lead}.where(leads: {project_id: params[:project_ids]})
      end
      call_attempts
    end

  end

end

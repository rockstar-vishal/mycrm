class CustomAudit < Audited::Audit

  acts_as_api

  api_accessible :public do |template|
    template.add :id
    template.add :status_from
    template.add :status_to
    template.add :comment_from
    template.add :comment_to
    template.add :assigned_from
    template.add :assigned_to
    template.add lambda{|a| a.user&.name}, as: :by
    template.add lambda{|a| a.created_at.strftime("%d %b %Y %I:%M %p")}, as: :date
  end

  def status_from
    if self.audited_changes.include?("status_id")
      status_id=self.audited_changes["status_id"][0] rescue '-'
      self.associated.statuses.find_by_id(status_id).name rescue '-'
    end
  end

  def status_to
    if self.audited_changes.include?("status_id")
      status_id=self.audited_changes["status_id"][1] rescue '-'
      self.associated.statuses.find_by_id(status_id).name rescue '-'
    end
  end

  def comment_from
    if self.audited_changes.include?("comment")
      self.audited_changes["comment"][0] rescue '-'
    end
  end

  def comment_to
    if self.audited_changes.include?("comment")
      self.audited_changes["comment"][1] rescue '-'
    end
  end

  def assigned_from
    if self.audited_changes.include?("user_id")
      user_id=self.audited_changes["user_id"][0] rescue '-'
      self.associated.users.find_by_id(user_id).name rescue '-'
    end
  end

  def assigned_to
    if self.audited_changes.include?("user_id")
      user_id=self.audited_changes["user_id"][1] rescue '-'
      self.associated.users.find_by_id(user_id).name rescue '-'
    end
  end
end
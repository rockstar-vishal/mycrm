class Users::Manager < ActiveRecord::Base
  belongs_to :user, class_name: "::User"
  belongs_to :manager, :class_name=>"::User"
  validates :manager, presence: true
  validates :manager_id, uniqueness: { scope: :user_id}

  validate :check_for_possible_recursion

  def check_for_possible_recursion
    if self.user.present? && self.user.manageables.ids.include?(self.manager_id)
      self.errors.add(:base, "Circular dependency detected in user to manager mapping")
      return false
    end
  end
end

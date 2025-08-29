require 'active_support/concern'

module CustomValidations

  extend ActiveSupport::Concern

  included do

    def unique_name
      if self.class.where("LOWER(REPLACE(name, ' ', '')) = (?)", "#{self.name.downcase.gsub(" ", "").strip}").present?
        self.errors.add(:base, "#{self.class.name} already exists")
        return false
      else
        return true
      end
    end

  end

end

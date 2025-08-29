require 'active_support/concern'

module AppSharable

  extend ActiveSupport::Concern

  included do

    class << self
      def find_id_from_name input_name, return_object=false
        resource = nil
        spaceless_downcase_name = input_name.strip.downcase.gsub(" ", "") rescue ""
        if spaceless_downcase_name.present?
          resource = all.where("replace(name, ' ', '') ILIKE ?", "#{spaceless_downcase_name}").last
        end
        return_object ? resource : resource&.id
      end
    end

  end

end
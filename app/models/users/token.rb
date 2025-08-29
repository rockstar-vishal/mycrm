class Users::Token < ActiveRecord::Base
  belongs_to :user, :class_name=>"::User"
  before_create :set_token

  def set_token
    self.token = generate_unique_token
  end

  private
    def generate_unique_token
      random = SecureRandom.hex(8)
      return random if self.class.find_by_token(random).blank?
      return generate_unique_token
    end
end

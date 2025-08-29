class Companies::ApiKey < ActiveRecord::Base
  belongs_to :company
  belongs_to :source
  belongs_to :project
  belongs_to :user
  validates :source, :project, :user, :key, :company, presence: true
  validates :key, uniqueness: true

  before_validation :set_key, on: :create

  def set_key
    self.key = generate_uniq_key
  end

  private

    def generate_uniq_key
      string = SecureRandom.hex(8)
      return string if check_uniqueness_of_key string
      return generate_uniq_key
    end


    def check_uniqueness_of_key key
      return !self.class.find_by_key(key).present?
    end
end

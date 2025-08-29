class Role < ActiveRecord::Base

  validates :name, presence: true, uniqueness: true
  has_many :users

  scope :active, -> { where(:active=>true) }

  scope :supervisor, -> {where(name: 'Supervisor')}

  SYSTEM_ADMIN_ROLE = 1
  SUPER_ROLE_ID = [1, 2]

  IDS_ORDER = [2, 8, 7, 5, 3, 4, 6, 9]

  scope :for_ids_with_order, ->(ids) {
    order = sanitize_sql_array(
      ["position((',' || id::text || ',') in ?)", ids.join(',') + ',']
    )
    where(:id => ids).order(order)
  }

end

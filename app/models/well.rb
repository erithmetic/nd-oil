class Well < ActiveRecord::Base
  attr_accessible :days_in_operation, :gas, :gas_sold, :oil, :read_at, :water
end

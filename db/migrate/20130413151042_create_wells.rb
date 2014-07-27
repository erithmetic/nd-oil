class CreateWells < ActiveRecord::Migration
  def change
    create_table :wells do |t|
      t.date :read_at
      t.integer :oil
      t.integer :water
      t.integer :gas
      t.integer :days_in_operation
      t.integer :gas_sold

      t.timestamps
    end
  end
end

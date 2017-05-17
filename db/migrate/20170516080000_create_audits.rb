class CreateAudits < ActiveRecord::Migration

  def up
    create_table :audits do |t|
      t.string :work_id, :limit => 16, :null => false
      t.string :user_id, :limit => 16, :null => false
      t.string :field, :limit => 32, :null => false
      t.text :before, null: false
      t.text :after, null: false

      t.timestamps null: false
    end
    add_index :audits, :work_id
    add_index :audits, :user_id
    add_index :audits, :created_at
  end

  def down
    drop_table :audits
  end
end

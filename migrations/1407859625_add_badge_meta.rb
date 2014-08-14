Sequel.migration do
  up do
    alter_table(:badges) do
      add_column :category, String, size: 255, null: false
      add_column :subcategory, String, size: 255, null: false
      add_column :level, Integer
    end
  end

  down do
    drop_column :badges, :category
    drop_column :badges, :subcategory
    drop_column :badges, :level
  end
end

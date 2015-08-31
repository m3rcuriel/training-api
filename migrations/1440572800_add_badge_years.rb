Sequel.migration do
  up do
    alter_table(:badges) do
      rename_column :level, :year # null = persistent across years
      add_column :is_deleted, TrueClass, null: false, default: false
    end
  end

  down do
    alter_table(:badges) do
      rename_column :year, :level
      drop_column :is_deleted
    end
  end
end

Sequel.migration do
  up do
    alter_table(:badges) do
      add_column :is_deleted, TrueClass, null: false, default: false
    end
  end

  down do
    alter_table(:badges) do
      drop_column :is_deleted
    end
  end
end

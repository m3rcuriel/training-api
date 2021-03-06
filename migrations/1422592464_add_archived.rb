Sequel.migration do
  up do
    alter_table(:users) do
      add_column :archived, TrueClass, null: false, default: false
    end
  end

  down do
    drop_column :users, :archived
  end
end

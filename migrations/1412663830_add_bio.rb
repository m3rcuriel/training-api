Sequel.migration do
  up do
    alter_table(:users) do
      add_column :bio, String, size: 255, null: false, default: ''
    end
  end

  down do
    drop_column :users, :bio
  end
end

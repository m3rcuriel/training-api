Sequel.migration do
  up do
    alter_table(:users_badges) do
      add_column :id, Bignum, size: 255, null: false
      add_column :time_created, DateTime, null: false
      add_column :time_updated, DateTime, null: false
    end
  end

  down do
    drop_column :users_badges, :id
    drop_column :users_badges, :time_created
    drop_column :users_badges, :time_updated
  end
end

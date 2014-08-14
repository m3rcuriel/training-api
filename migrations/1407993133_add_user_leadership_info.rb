Sequel.migration do
  up do
    alter_table(:users) do
      add_column :technical_group, String, size: 255
      add_column :nontechnical_group, String, size: 255
      add_column :title, String, size: 255
    end
  end

  down do
    drop_column :users, :technical_group
    drop_column :users, :nontechnical_group
    drop_column :users, :title
  end
end

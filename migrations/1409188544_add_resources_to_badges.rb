Sequel.migration do
  up do
    alter_table(:badges) do
      add_column :resources, String, text: true
    end
  end

  down do
    drop_column :badges, :resources
  end
end

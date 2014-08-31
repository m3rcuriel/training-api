Sequel.migration do
  up do
    alter_table(:badges) do
      add_column :verifiers, String, size: 255, null: false, default: 'Mentors'
    end
  end

  down do
    drop_column :badges, :verifiers
  end
end

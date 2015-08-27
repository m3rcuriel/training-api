Sequel.migration do
  up do
    alter_table(:badges) do
      rename_column :level, :year # null = persistent across years
    end
  end

  down do
    alter_table(:badges) do
      rename_column :year, :level
    end
  end
end

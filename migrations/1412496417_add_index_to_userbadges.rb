Sequel.migration do
  up do
    alter_table(:users_badges) do
      add_index(:id)
      add_index(:user_id)
      add_index(:badge_id)
    end
  end

  down do
    alter_table(:users_badges) do
      drop_index(:id)
      drop_index(:user_id)
      drop_index(:badge_id)
    end
  end
end

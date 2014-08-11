Sequel.migration do
  up do
    alter_table(:users) do
      add_column :username, String, size: 255, null: false, unique: true
    end

    alter_table(:users_badges) do
      add_foreign_key :reviewer_id, :users, type: Bignum, deferrable: true
      add_column :status, String, size: 255, null: false
    end

    alter_table(:badges) do
      add_column :learning_method, String, text: true
      add_column :assessment, String, text: true
    end
  end

  down do
    drop_column :badges, :assessment
    drop_column :badges, :learning_method
    drop_column :users_badges, :reviewer_id
    drop_column :users_badges, :status
    drop_column :users, :username
  end
end

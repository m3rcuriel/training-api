Sequel.migration do
  change do
    create_table(:users) do
      Bignum :id, null: false, primary_key: true
      DateTime :time_created, null: false
      DateTime :time_updated, null: false
      String :first_name, size: 255, null: false
      String :last_name, size: 255, null: false
      String :email, size: 255, null: false, unique: true
      String :permissions, size: 255, null: false
      String :password_key, size: 16*2, fixed: true
      String :password_salt, size: 12*2, fixed: true
      Integer :password_difficulty
    end

    create_table(:badges) do
      Bignum :id, null: false, primary_key: true
      DateTime :time_created, null: false
      DateTime :time_updated, null: false
      String :name, size: 255, null: false
      String :description, text: true, null: false
    end

    create_table(:users_badges) do
      foreign_key :user_id, :users, null: false, type: Bignum, deferrable: true
      foreign_key :badge_id, :badges, null: false, type: Bignum, deferrable: true
    end

  end
end

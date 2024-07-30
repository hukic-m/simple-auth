Sequel.migration do
  change do
    # Create roles table
    create_table(:roles) do
      primary_key :id
      String :name, null: false, unique: true
      String :description
    end

    # Create permissions table
    create_table(:permissions) do
      primary_key :id
      String :name, null: false, unique: true
      String :description
    end

    # Create account_roles table
    create_table(:account_roles) do
      foreign_key :account_id, :accounts, null: false, type: :Bignum
      foreign_key :role_id, :roles, null: false
      primary_key %i[account_id role_id]
    end

    # Create role_permissions table
    create_table(:role_permissions) do
      foreign_key :role_id, :roles, null: false
      foreign_key :permission_id, :permissions, null: false
      primary_key %i[role_id permission_id]
    end
  end
end

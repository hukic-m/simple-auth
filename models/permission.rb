# models/permission.rb
class Permission < Sequel::Model
  many_to_many :roles, join_table: :role_permissions
end

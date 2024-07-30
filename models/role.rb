# models/role.rb
require 'sequel'

class Role < Sequel::Model
  many_to_many :accounts, join_table: :account_roles
  many_to_many :permissions, join_table: :role_permissions

  def assign_permission(permission_name)
    permission = Permission.find(name: permission_name)
    add_permission(permission) if permission && !permissions.include?(permission)
  end

  def remove_permission(permission_name)
    permission = Permission.find(name: permission_name)
    remove_permission(permission) if permission && permissions.include?(permission)
  end
end

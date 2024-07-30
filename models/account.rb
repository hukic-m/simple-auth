require 'sequel'

class Account < Sequel::Model
  many_to_many :roles, join_table: :account_roles

  def permission?(permission_name)
    roles.any? { |role| role.permissions.map(&:name).include?(permission_name) }
  end

  def assign_role(role_name)
    role = Role.find(name: role_name)
    add_role(role) if role && !roles.include?(role)
  end

  def remove_role(role_name)
    role = Role.find(name: role_name)
    remove_role(role) if role && roles.include?(role)
  end

  def scopes
    roles.flat_map { |role| role.permissions.map(&:name) }.uniq
  end
end

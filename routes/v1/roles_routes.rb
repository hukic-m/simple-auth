require_relative '../../models/role'
require_relative '../../lib/rodauth_app'
require_relative '../../validations/new_role'
require 'json'

# Routes for managing roles in the application
class SimpleAuth
  plugin :rodauth, json: true, auth_class: RodauthApp
  plugin :all_verbs

  hash_branch '/v1', 'roles' do |r|
    rodauth.require_authentication

    r.is do
      r.get { handle_list_roles }
      r.post { handle_create_role }
    end

    r.on Integer do |role_id|
      role = Role[role_id]
      unless role
        response.status = 404
        next { errors: { role: 'not found' } }
      end

      r.is do
        r.get { handle_show_role(role) }
        r.patch { handle_update_role(role) }
        r.delete { handle_delete_role(role) }
      end

      r.on 'permissions' do
        r.get { handle_list_role_permissions(role) }

        r.on Integer do |permission_id|
          permission = Permission[permission_id]
          unless permission
            response.status = 404
            next { errors: { permission: 'not found' } }
          end

          r.is do
            r.post { handle_add_permission(role, permission) }
            r.delete { handle_remove_permission(role, permission) }
          end
        end
      end
    end
  end

  private

  def handle_list_roles
    roles = Role.all
    { data: roles.map(&:to_hash) }
  end

  def handle_create_role
    symbolized_params = parse_request_body
    contract = NewRole.new
    result = contract.call(symbolized_params[:role])

    if result.success?
      role = Role.create(result.to_h)
      response.status = 201
      { data: role.to_hash }
    else
      response.status = 422
      { errors: result.errors.to_h }
    end
  end

  def handle_show_role(role)
    { data: role.to_hash }
  end

  def handle_update_role(role)
    symbolized_params = parse_request_body[:role]
    contract = NewRole.new(operation: :update, current_role_id: role.id)
    current_params = role.values.merge(symbolized_params)
    result = contract.call(current_params)

    if result.success?
      role.update(result.to_h)
      response.status = 200
      { data: role.to_hash }
    else
      response.status = 422
      { errors: result.errors.to_h }
    end
  end

  def handle_delete_role(role)
    if role.destroy
      response.status = 200
      { message: 'Role deleted' }
    else
      response.status = 422
      { errors: { message: 'Failed to delete role' } }
    end
  end

  def handle_list_role_permissions(role)
    response.status = 200
    { data: role.permissions.map(&:to_hash) }
  end

  def handle_add_permission(role, permission)
    if role.permissions.include?(permission)
      response.status = 409
      { errors: { permission: 'already exists' } }
    else
      role.add_permission(permission)
      response.status = 201
      { data: permission.to_hash }
    end
  end

  def handle_remove_permission(role, permission)
    if role.permissions.include?(permission)
      role.remove_permission(permission)
      response.status = 204
      {}
    else
      response.status = 404
      { errors: { permission: 'not found' } }
    end
  end

  def parse_request_body
    JSON.parse(request.body.read, symbolize_names: true)
  rescue JSON::ParserError
    response.status = 400
    halt({ errors: { request: 'invalid JSON' } })
  end
end

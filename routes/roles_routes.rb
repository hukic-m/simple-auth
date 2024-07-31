require_relative '../models/role'
require_relative '../lib/rodauth_app'
require_relative '../validations/new_role'

# Routes for managing roles in the application
class RolesRoutes < Roda
  plugin :rodauth, json: true, auth_class: RodauthApp
  plugin :all_verbs

  route do |r|
    rodauth.require_authentication

    r.on 'roles' do
      r.is do
        r.get { handle_list_roles }
        r.post { handle_create_role }
      end

      r.on Integer do |id|
        role = Role[id]
        unless role
          response.status = 404
          next { errors: { role: 'not found' } }
        end

        r.is do
          r.get { handle_show_role(role) }
          r.patch { handle_update_role(role) }
          r.delete { handle_delete_role(role) }
        end
      end
    end
  end

  private

  # Handles listing all roles
  #
  # @return [Hash] The list of roles
  def handle_list_roles
    roles = Role.all
    { data: roles.map(&:to_hash) }
  end

  # Handles creating a new role
  #
  # @return [Hash] The created role or errors
  def handle_create_role
    symbolized_params = JSON.parse(request.body.read, symbolize_names: true)
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

  # Handles showing a specific role
  #
  # @param role [Role] The role to show
  # @return [Hash] The role data
  def handle_show_role(role)
    { data: role.to_hash }
  end

  # Handles updating an existing role
  #
  # @param role [Role] The role to update
  # @return [Hash] The updated role or errors
  def handle_update_role(role)
    symbolized_params = JSON.parse(request.body.read, symbolize_names: true)[:role]
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

  # Handles deleting a specific role
  #
  # @param role [Role] The role to delete
  # @return [Hash] A success message or errors
  def handle_delete_role(role)
    if role.destroy
      response.status = 200
      { message: 'Role deleted' }
    else
      response.status = 422
      { errors: { message: 'Failed to delete role' } }
    end
  end
end

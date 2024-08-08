require 'roda'
require 'sequel'
require_relative '../../models/permission'
require_relative '../../models/role'
require_relative '../../lib/rodauth_app'
require_relative '../../validations/new_permission'

class SimpleAuth
  plugin :rodauth, json: true, auth_class: RodauthApp
  plugin :all_verbs
  plugin :halt

  hash_branch '/v1', 'permissions' do |r|
    # Ensure the user is authenticated
    rodauth.require_authentication
    rodauth.require_role(ENV['ROLE_ADMIN'].split(','))

    # GET /permissions
    r.is do
      r.get do
        permissions = Permission.all
        permissions.map(&:to_hash)
      end

      r.post do
        create_permission(r)
      end
    end

    r.on Integer do |id|
      permission = Permission[id]

      # Ensure the permission exists
      r.halt(404, { error: 'Permission not found' }.to_json) unless permission

      r.is do
        # GET /permissions/:id
        r.get do
          permission.to_hash
        end

        # PATCH /permissions/:id
        r.patch do
          update_permission(r, permission)
        end

        # DELETE /permissions/:id
        r.delete do
          delete_permission(permission)
        end
      end
    end
  end

  private

  # Handles creating a new permission
  #
  # @param r [Roda::RodaRequest] The Roda request object
  # @return [Hash] The created permission or validation errors
  def create_permission(request)
    permission_contract = NewPermission.new
    svc = permission_contract.call(request.params['permission'], update: false)

    if svc.success?
      permission = Permission.create(request.params['permission'])
      permission.to_hash
    else
      response.status = 422
      { errors: svc.errors.to_h }
    end
  end

  # Handles updating an existing permission
  #
  # @param r [Roda::RodaRequest] The Roda request object
  # @param permission [Permission] The permission to update
  # @return [Hash] The updated permission or validation errors
  def update_permission(request, permission)
    permission_contract = NewPermission.new
    svc = permission_contract.call(request.params['permission'], { update: true, permission_id: permission.id })

    if svc.success?
      permission.update(request.params['permission'])
      permission.to_hash
    else
      response.status = 422
      { errors: svc.errors.to_h }
    end
  end

  # Handles deleting a permission
  #
  # @param permission [Permission] The permission to delete
  # @return [Hash] Confirmation message
  def delete_permission(permission)
    permission.destroy
    { message: 'Permission deleted' }
  end
end

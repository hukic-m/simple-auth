require_relative '../models/role'
require_relative '../lib/rodauth_app'

class PermissionsRoutes < Roda
  plugin :rodauth, json: true, auth_class: RodauthApp
  plugin :all_verbs
  # Represents the routes for managing permissions in the application.
  route do |r|
    rodauth.require_authentication
    # Handles requests related to permissions.
    r.on 'permissions' do
      # Handles GET requests to retrieve all permissions.
      r.get do
        permissions = Permission.all
        permissions.map(&:to_hash)
      end

      # Handles POST requests to create a new permission.
      r.post do
        permission = Permission.create(r.params)
        permission.to_hash
      end
    end

    # Handles requests related to a specific permission.
    r.on 'permissions', Integer do |id|
      permission = Permission[id]

      # Handles GET requests to retrieve a specific permission.
      r.get do
        permission.to_hash
      end

      # Handles PATCH requests to update a specific permission.
      r.patch do
        permission.update(r.params)
        permission.to_hash
      end

      # Handles DELETE requests to delete a specific permission.
      r.delete do
        permission.destroy
        { message: 'Permission deleted' }
      end
    end
  end
end

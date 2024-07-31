require_relative '../models/role'
require_relative '../lib/rodauth_app'
require_relative '../validations/new_role'

class RolesRoutes < Roda
  plugin :rodauth, json: true, auth_class: RodauthApp
  plugin :all_verbs
  new_role = NewRole.new(update_method: false)

  route do |r|
    rodauth.require_authentication

    r.on 'roles' do
      # Handle routes with an integer ID first to avoid conflicts
      r.on Integer do |id|
        role = Role[id]

        unless role
          response.status = 404
          next { errors: { role: 'not found' } }
        end

        # GET api/v1/roles/:id
        r.get do
          { data: role.to_hash }
        end

        # DELETE api/v1/roles/:id
        r.delete do
          if role.destroy
            response.status = 200
            { message: 'Role deleted' }
          else
            response.status = 422
            { errors: { message: 'Failed to delete role' } }
          end
        end
      end

      # GET api/v1/roles
      r.get do
        roles = Role.all
        { data: roles.map(&:to_hash) }
      end

      r.post do
        symbolized_params = JSON.parse(request.body.read, symbolize_names: true)
        valid_role = new_role.call(symbolized_params[:role])

        if valid_role.success?
          role = Role.create(valid_role.to_h)
          response.status = 201
          { data: role.to_hash }
        else
          response.status = 422
          { errors: valid_role.errors.to_h }
        end
      end
    end
  end
end

#
# This file contains the implementation of the routes for checking roles and permissions in the SimpleAuth application.
#
# The routes are defined under the '/v1/roles-permissions' namespace and require authentication for access.
#
# == Routes
#
# - POST '/v1/roles-permissions/check_role'
#   - This route is used to check if the authenticated user has the required roles.
#   - It expects a JSON payload in the request body containing the 'roles' array.
#   - If the user has all the required roles, it returns a JSON response with { verified: true }.
#   - If the request body is not a valid JSON or the user does not have the required roles, it returns a 400 Bad Request response.
#
# - POST '/v1/roles-permissions/check_permission'
#   - This route is used to check if the authenticated user has the required permissions.
#   - It expects a JSON payload in the request body containing the 'permissions' array.
#   - If the user has all the required permissions, it returns a JSON response with { verified: true }.
#   - If the request body is not a valid JSON or the user does not have the required permissions, it returns a 400 Bad Request response.
#
# == Usage
#
# To use these routes, make sure to include the SimpleAuth plugin and enable the 'all_verbs' and 'halt' plugins.
# Then, mount the routes under the '/v1/roles-permissions' namespace.
#
# Example:
#
#   class SimpleAuth
#     plugin :all_verbs
#     plugin :halt
#
#     hash_branch '/v1', 'roles-permissions' do |r|
#       # Define the routes here
#     end
#   end
#

class SimpleAuth
  hash_branch '/v1', 'roles-permissions' do |r|
    r.post 'check_role' do
      rodauth.require_authentication

      required_roles = parse_request_body(r, 'roles')

      if required_roles
        return { verified: true } if rodauth.require_role(required_roles)

        response.status = 403
        { verified: false, error: 'Forbidden' }.to_json
      end
    end

    r.post 'check_permission' do
      rodauth.require_authentication

      required_permissions = parse_request_body(r, 'permissions')

      if required_permissions
        return { verified: true } if rodauth.require_permission(required_permissions)

        response.status = 403
        { verified: false, error: 'Forbidden' }.to_json
      end
    end
  end

  private

  #
  # Parses the JSON request body and extracts the specified key.
  #
  # @param request [Roda::RodaRequest] the Roda request object
  # @param key [String] the key to extract from the JSON body
  # @return [Array] the extracted values or nil if the JSON is invalid
  #
  def parse_request_body(request, key)
    request_data = JSON.parse(request.body.read)
    request_data[key] || []
  rescue JSON::ParserError
    response.status = 400
    response.write({ error: 'Invalid JSON' }.to_json)
    request.halt
    nil
  end
end

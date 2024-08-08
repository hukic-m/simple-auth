# Module containing helper methods for authorization checks.
module AuthHelpers
  # Ensures the current user has at least one of the required roles.
  #
  # @param required_roles [Array<String>] the roles required for access.
  # @return [Boolean] true if the user has one of the required roles, otherwise denies access.
  # @raise [ArgumentError] if required_roles is not an array.
  def require_role(required_roles)
    raise ArgumentError, 'required roles must be an array' unless required_roles.is_a?(Array)

    account_roles = @jwt_payload['roles']
    return true if (account_roles & required_roles).any?

    deny_access
  end

  # Ensures the current user has at least one of the required permissions.
  #
  # @param required_permissions [Array<String>] the permissions required for access.
  # @return [Boolean] true if the user has one of the required permissions, otherwise denies access.
  # @raise [ArgumentError] if required_permissions is not an array.
  def require_permission(required_permissions)
    raise ArgumentError, 'required permissions must be an array' unless required_permissions.is_a?(Array)

    account_permissions = @jwt_payload['permissions']
    return true if (account_permissions & required_permissions).any?

    deny_access
  end

  # Middleware to check if the current user is accessing their own account or is an admin.
  #
  # @return [Boolean] true if the user is accessing their own account or is an admin, otherwise denies access.
  def account_middleware
    account_id_in_path = request.path_info[%r{/accounts/(\d+)}, 1].to_i
    return true if account_id_in_path == @jwt_payload['account_id']

    return true if require_role(ENV['ROLE_ADMIN'].split(','))

    deny_access
  end

  private

  # Denies access by setting the response status to 403 and writing an error message.
  #
  # @return [void]
  def deny_access
    response.status = 403
    response.write({ error: 'Forbidden' }.to_json)
    request.halt
  end
end

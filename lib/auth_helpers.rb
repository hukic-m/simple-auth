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
    return true if user_own_account? || user_admin?

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

  def user_own_account?
    @jwt_payload['account_id'] == current_user_account_id
  end

  def user_admin?
    @jwt_payload['roles'].include?('admin')
  end

  def current_user_account_id
    @jwt_payload['account_id']
  end
end

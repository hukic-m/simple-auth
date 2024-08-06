require 'dry-validation'

# Contract for validating Role data
#
# @example
#   contract = NewRole.new(operation: :update, current_role_id: 1)
#   result = contract.call(name: 'New Role', description: 'Description')
#
# @attr_accessor [Hash] addition_context The context for the validation (operation type and current role ID)
class NewRole < Dry::Validation::Contract
  attr_accessor :addition_context

  # Parameters required for the contract
  params do
    required(:name).filled(:string)
    required(:description).filled(:string)
  end

  # Initializes the contract with context
  #
  # @param context [Hash] The context for the validation (operation type and current role ID)
  def initialize(context = {})
    super()
    @addition_context = context
  end

  # Rule for validating the name attribute
  #
  # Ensures the name is unique based on the operation type (create or update)
  #
  # @param [Symbol] :name The attribute being validated
  rule(:name) do
    current_role_id = addition_context[:current_role_id]

    if addition_context[:operation] == :update
      current_role = Role.where(id: current_role_id).first

      # Check if the name has changed and ensure the new name is unique
      key.failure('must be unique') if value != current_role.name && Role.where(name: value).exclude(id: current_role_id).count.positive?
    else
      # For create operation, ensure the name is unique
      key.failure('must be unique') unless Role.where(name: value).empty?
    end
  end
end

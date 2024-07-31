require 'dry-validation'
require 'byebug'

class NewRole < Dry::Validation::Contract
  attr_accessor :addition_context

  params do
    required(:name).filled(:string)
    required(:description).filled(:string)
  end

  def initialize(context = {})
    super()
    @addition_context = context
  end

  rule(:name) do
    current_role_id = addition_context[:current_role_id]
    if addition_context[:operation] == :update
      key.failure('must be unique') unless Role.where(name: value).all.any? { |role| role.id == current_role_id }
    else
      key.failure('must be unique') unless Role.where(name: value).empty?
    end
  end
end

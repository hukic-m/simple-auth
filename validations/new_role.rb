require 'dry-validation'

class NewRole < Dry::Validation::Contract
  params do
    required(:name).filled(:string)
    required(:description).filled(:string)
  end

  rule(:name) do
    key.failure('must be unique') unless Role.where(name: value).first.empty
  end
end

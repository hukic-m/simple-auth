require 'dry-validation'

class NewPermission < Dry::Validation::Contract
  params do
    required(:name).filled(:string)
    required(:description).filled(:string)
  end

  rule(:name) do |context:|
    if context[:update]
      permission_id = context[:permission_id]

      current_permission = Permission.where(id: permission_id).first

      key.failure('must be unique') if value != current_permission.name && Permission.where(name: value).exclude(id: permission_id).count.positive?
    else
      key.failure('must be unique') unless Permission.where(name: value).empty?
    end
  end
end

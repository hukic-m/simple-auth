require 'byebug'
class SimpleAuth
  plugin :all_verbs
  plugin :halt

  hash_branch '/v1', 'accounts' do |r|
    rodauth.require_authentication

    # GET /accounts
    r.is do
      rodauth.require_role(ENV['ROLE_ADMIN'].split(','))

      r.get do
        accounts = Account.all
        accounts.map(&:to_hash)
      end
    end

    r.on Integer do |id|
      rodauth.account_middleware

      account = Account[id]

      # Ensure the account exists
      r.halt(404, { error: 'Account not found' }.to_json) unless account

      r.is do
        # GET /accounts/:id
        r.get do
          account.to_hash
        end

        # PATCH /accounts/:id
        r.patch do
          body = JSON.parse(request.body.read, symbolize_names: true)
          account.update(account.to_hash.except(:id).merge(body[:account]))

          response.status = 422 unless account.valid?
          { data: account.to_hash }
        end

        # DELETE /accounts/:id
        r.delete do
          rodauth.require_role(ENV['ROLE_ADMIN'].split(','))
          account.destroy
          response.status = 204
          {}
        end
      end

      # POST /accounts/:id/assign_role
      r.post 'assign_role' do
        rodauth.require_role(ENV['ROLE_ADMIN'].split(','))

        body = JSON.parse(request.body.read, symbolize_names: true)

        role_name = body[:role][:name]
        if role_name && account.assign_role(role_name)
          response.status = 200
          { message: "Role '#{role_name}' assigned to account." }
        else
          response.status = 404
          { error: "Role '#{role_name}' not found." }
        end
      end
    end
  end
end

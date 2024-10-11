class SimpleAuth
  plugin :all_verbs
  plugin :halt

  hash_branch '/v1', 'accounts' do |r|
    rodauth.require_authentication

    # GET /v1/accounts
    r.is do
      rodauth.require_role(ENV['ROLE_ADMIN'].split(','))

      r.get do
        accounts = Account.all
        accounts.map(&:to_hash)
      end
    end

    r.on String do |id_or_email|
      rodauth.account_middleware

      account = if id_or_email =~ /^\d+$/
                  Account[id_or_email.to_i]
                else
                  Account.find_by(email: id_or_email)
                end

      r.halt(404, { error: 'Account not found' }.to_json) unless account

      r.is do
        # GET /accounts/:id_or_email
        r.get do
          account.to_hash
        end

        # PATCH /accounts/:id_or_email
        r.patch do
          body = JSON.parse(request.body.read, symbolize_names: true)
          account.update(account.to_hash.except(:id).merge(body[:account]))

          response.status = 422 unless account.valid?
          { data: account.to_hash }
        end

        # DELETE /accounts/:id_or_email
        r.delete do
          rodauth.require_role(ENV['ROLE_ADMIN'].split(','))
          account.destroy
          response.status = 204
          {}
        end
      end

      # POST /accounts/:id_or_email/assign_role
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

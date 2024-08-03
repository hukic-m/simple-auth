require_relative '../models/account'
require_relative '../lib/rodauth_app'
require 'json'

class AccountRoutes < Roda
  plugin :rodauth, json: true, auth_class: RodauthApp
  plugin :all_verbs
  plugin :halt

  route do |r|
    rodauth.require_authentication

    # GET /accounts
    r.is do
      r.get do
        accounts = Account.all
        accounts.map(&:to_hash)
      end
    end

    r.on Integer do |id|
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
          account.destroy
          response.status = 204
          {}
        end
      end
    end
  end
end

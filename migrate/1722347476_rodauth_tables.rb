require 'rodauth/migrations'

Sequel.migration do
  up do
    if database_type == :postgres
      run 'CREATE EXTENSION IF NOT EXISTS citext'
    end

    extension :date_arithmetic

    # Used by the account verification and close account features
    create_table(:account_statuses) do
      Integer :id, primary_key: true
      String :name, null: false, unique: true
    end
    from(:account_statuses).import(%i[id name], [[1, 'Unverified'], [2, 'Verified'], [3, 'Closed']])

    db = self
    create_table(:accounts) do
      primary_key :id, type: :Bignum
      foreign_key :status_id, :account_statuses, null: false, default: 1
      if db.database_type == :postgres
        citext :email, null: false
        constraint :valid_email, email: /^[^,;@ \r\n]+@[^,@; \r\n]+\.[^,@; \r\n]+$/
      else
        String :email, null: false
      end
      if db.supports_partial_indexes?
        index :email, unique: true, where: { status_id: [1, 2] }
      else
        index :email, unique: true
      end
    end

    deadline_opts = proc do |days|
      if database_type == :mysql
        { null: false }
      else
        { null: false, default: Sequel.date_add(Sequel::CURRENT_TIMESTAMP, days:) }
      end
    end

    # Used by the audit logging feature
    json_type = case database_type
                when :postgres
                  :jsonb
                when :sqlite, :mysql
                  :json
                else
                  String
                end
    create_table(:account_authentication_audit_logs) do
      primary_key :id, type: :Bignum
      foreign_key :account_id, :accounts, null: false, type: :Bignum
      DateTime :at, null: false, default: Sequel::CURRENT_TIMESTAMP
      String :message, null: false
      column :metadata, json_type
      index %i[account_id at], name: :audit_account_at_idx
      index :at, name: :audit_at_idx
    end

    # Used by the password reset feature
    create_table(:account_password_reset_keys) do
      foreign_key :id, :accounts, primary_key: true, type: :Bignum
      String :key, null: false
      DateTime :deadline, deadline_opts[1]
      DateTime :email_last_sent, null: false, default: Sequel::CURRENT_TIMESTAMP
    end

    # Used by the jwt refresh feature
    create_table(:account_jwt_refresh_keys) do
      primary_key :id, type: :Bignum
      foreign_key :account_id, :accounts, null: false, type: :Bignum
      String :key, null: false
      DateTime :deadline, deadline_opts[1]
      index :account_id, name: :account_jwt_rk_account_id_idx
    end

    # Used by the account verification feature
    create_table(:account_verification_keys) do
      foreign_key :id, :accounts, primary_key: true, type: :Bignum
      String :key, null: false
      DateTime :requested_at, null: false, default: Sequel::CURRENT_TIMESTAMP
      DateTime :email_last_sent, null: false, default: Sequel::CURRENT_TIMESTAMP
    end

    # Used by the verify login change feature
    create_table(:account_login_change_keys) do
      foreign_key :id, :accounts, primary_key: true, type: :Bignum
      String :key, null: false
      String :login, null: false
      DateTime :deadline, deadline_opts[1]
    end

    # Used by the remember me feature
    create_table(:account_remember_keys) do
      foreign_key :id, :accounts, primary_key: true, type: :Bignum
      String :key, null: false
      DateTime :deadline, deadline_opts[14]
    end

    # Used by the lockout feature
    create_table(:account_login_failures) do
      foreign_key :id, :accounts, primary_key: true, type: :Bignum
      Integer :number, null: false, default: 1
    end
    create_table(:account_lockouts) do
      foreign_key :id, :accounts, primary_key: true, type: :Bignum
      String :key, null: false
      DateTime :deadline, deadline_opts[1]
      DateTime :email_last_sent
    end

    # Used by the email auth feature
    create_table(:account_email_auth_keys) do
      foreign_key :id, :accounts, primary_key: true, type: :Bignum
      String :key, null: false
      DateTime :deadline, deadline_opts[1]
      DateTime :email_last_sent, null: false, default: Sequel::CURRENT_TIMESTAMP
    end

    # Used by the password expiration feature
    create_table(:account_password_change_times) do
      foreign_key :id, :accounts, primary_key: true, type: :Bignum
      DateTime :changed_at, null: false, default: Sequel::CURRENT_TIMESTAMP
    end

    # Used by the account expiration feature
    create_table(:account_activity_times) do
      foreign_key :id, :accounts, primary_key: true, type: :Bignum
      DateTime :last_activity_at, null: false
      DateTime :last_login_at, null: false
      DateTime :expired_at
    end

    # Used by the single session feature
    create_table(:account_session_keys) do
      foreign_key :id, :accounts, primary_key: true, type: :Bignum
      String :key, null: false
    end

    # Used by the active sessions feature
    create_table(:account_active_session_keys) do
      foreign_key :account_id, :accounts, type: :Bignum
      String :session_id
      Time :created_at, null: false, default: Sequel::CURRENT_TIMESTAMP
      Time :last_use, null: false, default: Sequel::CURRENT_TIMESTAMP
      primary_key %i[account_id session_id]
    end

    # Used by the webauthn feature
    create_table(:account_webauthn_user_ids) do
      foreign_key :id, :accounts, primary_key: true, type: :Bignum
      String :webauthn_id, null: false
    end
    create_table(:account_webauthn_keys) do
      foreign_key :account_id, :accounts, type: :Bignum
      String :webauthn_id
      String :public_key, null: false
      Integer :sign_count, null: false
      Time :last_use, null: false, default: Sequel::CURRENT_TIMESTAMP
      primary_key %i[account_id webauthn_id]
    end

    # Used by the otp feature
    create_table(:account_otp_keys) do
      foreign_key :id, :accounts, primary_key: true, type: :Bignum
      String :key, null: false
      Integer :num_failures, null: false, default: 0
      Time :last_use, null: false, default: Sequel::CURRENT_TIMESTAMP
    end

    # Used by the otp_unlock feature
    create_table(:account_otp_unlocks) do
      foreign_key :id, :accounts, primary_key: true, type: :Bignum
      Integer :num_successes, null: false, default: 1
      Time :next_auth_attempt_after, null: false, default: Sequel::CURRENT_TIMESTAMP
    end

    # Used by the recovery codes feature
    create_table(:account_recovery_codes) do
      foreign_key :id, :accounts, type: :Bignum
      String :code
      primary_key %i[id code]
    end

    # Used by the sms codes feature
    create_table(:account_sms_codes) do
      foreign_key :id, :accounts, primary_key: true, type: :Bignum
      String :phone_number, null: false
      Integer :num_failures
      String :code
      DateTime :code_issued_at, null: false, default: Sequel::CURRENT_TIMESTAMP
    end

    # Used by the password hash feature
    create_table(:account_password_hashes) do
      foreign_key :id, :accounts, primary_key: true, type: :Bignum
      String :password_hash, null: false
    end
    Rodauth.create_database_authentication_functions(self)

    # Used by the disallow password reuse feature
    create_table(:account_previous_password_hashes) do
      primary_key :id, type: :Bignum
      foreign_key :account_id, :accounts, type: :Bignum
      String :password_hash, null: false
    end
    Rodauth.create_database_previous_password_check_functions(self)

    case database_type
    when :postgres
      user = get(Sequel.lit('current_user')).sub(/_password\z/, '')
      run 'REVOKE ALL ON account_password_hashes FROM public'
      run 'REVOKE ALL ON FUNCTION rodauth_get_salt(int8) FROM public'
      run 'REVOKE ALL ON FUNCTION rodauth_valid_password_hash(int8, text) FROM public'
      run "GRANT INSERT, UPDATE, DELETE ON account_password_hashes TO #{user}"
      run "GRANT SELECT(id) ON account_password_hashes TO #{user}"
      run "GRANT EXECUTE ON FUNCTION rodauth_get_salt(int8) TO #{user}"
      run "GRANT EXECUTE ON FUNCTION rodauth_valid_password_hash(int8, text) TO #{user}"
      run 'REVOKE ALL ON account_previous_password_hashes FROM public'
      run 'REVOKE ALL ON FUNCTION rodauth_get_previous_salt(int8) FROM public'
      run 'REVOKE ALL ON FUNCTION rodauth_previous_password_hash_match(int8, text) FROM public'
      run "GRANT INSERT, UPDATE, DELETE ON account_previous_password_hashes TO #{user}"
      run "GRANT SELECT(id, account_id) ON account_previous_password_hashes TO #{user}"
      run "GRANT USAGE ON account_previous_password_hashes_id_seq TO #{user}"
      run "GRANT EXECUTE ON FUNCTION rodauth_get_previous_salt(int8) TO #{user}"
      run "GRANT EXECUTE ON FUNCTION rodauth_previous_password_hash_match(int8, text) TO #{user}"
    when :mysql
      user = get(Sequel.lit('current_user')).sub(/_password@/, '@')
      db_name = get(Sequel.function(:database))
      run "GRANT EXECUTE ON #{db_name}.* TO #{user}"
      run "GRANT INSERT, UPDATE, DELETE ON account_password_hashes TO #{user}"
      run "GRANT SELECT (id) ON account_password_hashes TO #{user}"
      run "GRANT INSERT, UPDATE, DELETE ON account_previous_password_hashes TO #{user}"
      run "GRANT SELECT (id, account_id) ON account_previous_password_hashes TO #{user}"
    when :mssql
      user = get(Sequel.function(:DB_NAME))
      run "GRANT EXECUTE ON rodauth_get_salt TO #{user}"
      run "GRANT EXECUTE ON rodauth_valid_password_hash TO #{user}"
      run "GRANT INSERT, UPDATE, DELETE ON account_password_hashes TO #{user}"
      run "GRANT SELECT ON account_password_hashes(id) TO #{user}"
      run "GRANT EXECUTE ON rodauth_get_previous_salt TO #{user}"
      run "GRANT EXECUTE ON rodauth_previous_password_hash_match TO #{user}"
      run "GRANT INSERT, UPDATE, DELETE ON account_previous_password_hashes TO #{user}"
      run "GRANT SELECT ON account_previous_password_hashes(id, account_id) TO #{user}"
    when :postgres
      user = get(Sequel.lit('current_user')) + '_password'
      run "GRANT REFERENCES ON accounts TO #{user}"
    when :mysql, :mssql
      user = if database_type == :mysql
               get(Sequel.lit('current_user')).sub(/_password@/, '@')
             else
               get(Sequel.function(:DB_NAME))
             end
      run "GRANT SELECT, INSERT, UPDATE, DELETE ON account_statuses TO #{user}"
      run "GRANT SELECT, INSERT, UPDATE, DELETE ON accounts TO #{user}"
      run "GRANT SELECT, INSERT, UPDATE, DELETE ON account_authentication_audit_logs TO #{user}"
      run "GRANT SELECT, INSERT, UPDATE, DELETE ON account_password_reset_keys TO #{user}"
      run "GRANT SELECT, INSERT, UPDATE, DELETE ON account_jwt_refresh_keys TO #{user}"
      run "GRANT SELECT, INSERT, UPDATE, DELETE ON account_verification_keys TO #{user}"
      run "GRANT SELECT, INSERT, UPDATE, DELETE ON account_login_change_keys TO #{user}"
      run "GRANT SELECT, INSERT, UPDATE, DELETE ON account_remember_keys TO #{user}"
      run "GRANT SELECT, INSERT, UPDATE, DELETE ON account_login_failures TO #{user}"
      run "GRANT SELECT, INSERT, UPDATE, DELETE ON account_email_auth_keys TO #{user}"
      run "GRANT SELECT, INSERT, UPDATE, DELETE ON account_lockouts TO #{user}"
      run "GRANT SELECT, INSERT, UPDATE, DELETE ON account_password_change_times TO #{user}"
      run "GRANT SELECT, INSERT, UPDATE, DELETE ON account_activity_times TO #{user}"
      run "GRANT SELECT, INSERT, UPDATE, DELETE ON account_session_keys TO #{user}"
      run "GRANT SELECT, INSERT, UPDATE, DELETE ON account_active_session_keys TO #{user}"
      run "GRANT SELECT, INSERT, UPDATE, DELETE ON account_webauthn_user_ids TO #{user}"
      run "GRANT SELECT, INSERT, UPDATE, DELETE ON account_webauthn_keys TO #{user}"
      run "GRANT SELECT, INSERT, UPDATE, DELETE ON account_otp_keys TO #{user}"
      run "GRANT SELECT, INSERT, UPDATE, DELETE ON account_otp_unlocks TO #{user}"
      run "GRANT SELECT, INSERT, UPDATE, DELETE ON account_recovery_codes TO #{user}"
      run "GRANT SELECT, INSERT, UPDATE, DELETE ON account_sms_codes TO #{user}"
    end
  end

  down do
    Rodauth.drop_database_previous_password_check_functions(self)
    Rodauth.drop_database_authentication_functions(self)
    drop_table(:account_sms_codes,
               :account_recovery_codes,
               :account_otp_unlocks,
               :account_otp_keys,
               :account_webauthn_keys,
               :account_webauthn_user_ids,
               :account_session_keys,
               :account_active_session_keys,
               :account_activity_times,
               :account_password_change_times,
               :account_email_auth_keys,
               :account_lockouts,
               :account_login_failures,
               :account_remember_keys,
               :account_login_change_keys,
               :account_verification_keys,
               :account_jwt_refresh_keys,
               :account_password_reset_keys,
               :account_authentication_audit_logs,
               :account_password_hashes,
               :account_previous_password_hashes,
               :accounts,
               :account_statuses)
  end
end
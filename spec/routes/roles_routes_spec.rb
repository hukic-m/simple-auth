require 'spec_helper'
require 'roda'
require 'rack/test'
require 'json'
require_relative '../../app'

RSpec.describe RolesRoutes do
  include Rack::Test::Methods

  def app
    App.freeze.app
  end

  let(:json_headers) { { 'CONTENT_TYPE' => 'application/json' } }

  before do
    allow_any_instance_of(RodauthApp).to receive(:require_authentication).and_return(true)
  end

  before(:each) do
    TEST_DB[:roles].delete
    TEST_DB[:permissions].delete
  end

  def json_response
    JSON.parse(last_response.body)
  end

  describe 'GET /api/v1/roles' do
    before do
      TEST_DB[:roles].multi_insert([
                                     { name: 'Role 1', description: 'Role 1' },
                                     { name: 'Role 2', description: 'Role 2' }
                                   ])
    end

    it 'returns all roles' do
      get '/api/v1/roles'
      expect(last_response.status).to eq(200)
      expect(json_response['data'].length).to eq(2)
    end
  end

  describe 'GET /api/v1/roles/:id' do
    context 'when the role exists' do
      let(:role_id) { TEST_DB[:roles].insert(name: 'Test Role') }

      it 'returns a specific role' do
        get "/api/v1/roles/#{role_id}"
        expect(last_response.status).to eq(200)
        expect(json_response['data']['name']).to eq('Test Role')
      end
    end

    context 'when the role does not exist' do
      it 'returns 404' do
        get '/api/v1/roles/999999'
        expect(last_response.status).to eq(404)
      end
    end
  end

  describe 'POST /api/v1/roles' do
    context 'with valid params' do
      let(:valid_params) { { role: { name: 'New Role', description: 'New Role' } }.to_json }

      it 'creates a new role' do
        post '/api/v1/roles', valid_params, json_headers
        expect(last_response.status).to eq(201)
        expect(json_response['data']['name']).to eq('New Role')
      end
    end

    context 'with invalid params' do
      let(:invalid_params) { { role: { name: '' } }.to_json }

      it 'returns errors' do
        post '/api/v1/roles', invalid_params, json_headers
        expect(last_response.status).to eq(422)
      end
    end
  end

  describe 'DELETE /api/v1/roles/:id' do
    context 'when the role exists' do
      let(:role_id) { TEST_DB[:roles].insert(name: 'Role to Delete') }

      it 'deletes the role' do
        delete "/api/v1/roles/#{role_id}"
        expect(last_response.status).to eq(200)
        expect(TEST_DB[:roles][id: role_id]).to be_nil
      end
    end

    context 'when the role does not exist' do
      it 'returns 404' do
        delete '/api/v1/roles/999999'
        expect(last_response.status).to eq(404)
      end
    end
  end

  describe 'PATCH /api/v1/roles/:id' do
    context 'when the role exists' do
      let(:role_id) { TEST_DB[:roles].insert(name: 'Role1', description: 'Role1') }

      context 'with valid name param' do
        let(:valid_params) { { role: { name: 'Role1Update' } }.to_json }

        it 'updates the role' do
          patch "/api/v1/roles/#{role_id}", valid_params, json_headers
          expect(last_response.status).to eq(200)
          expect(json_response['data']['name']).to eq('Role1Update')
        end
      end

      context 'with valid description param and name not changed' do
        let(:valid_params) { { role: { description: 'Role1DescUpdate' } }.to_json }

        it 'updates the role' do
          patch "/api/v1/roles/#{role_id}", valid_params, json_headers
          expect(last_response.status).to eq(200)
          expect(json_response['data']['description']).to eq('Role1DescUpdate')
        end
      end

      context 'with invalid params' do
        let(:invalid_params) { { role: { name: '' } }.to_json }

        it 'returns errors' do
          patch "/api/v1/roles/#{role_id}", invalid_params, json_headers
          expect(last_response.status).to eq(422)
        end
      end
    end

    context 'when the role does not exist' do
      it 'returns 404' do
        patch '/api/v1/roles/999999', '{}', json_headers
        expect(last_response.status).to eq(404)
      end
    end
  end

  describe 'GET /api/v1/roles/:id/permissions' do
    context 'when the role exists' do
      let(:role_id) { TEST_DB[:roles].insert(name: 'Role with Permissions') }
      let(:permission) { Permission.create(name: 'view', description: 'View permission') }

      before do
        role = Role[role_id]
        role.add_permission(permission)
      end

      it 'returns all permissions for the role' do
        get "/api/v1/roles/#{role_id}/permissions"
        expect(last_response.status).to eq(200)
        expect(json_response['data'].length).to eq(1)
        expect(json_response['data'].first['name']).to eq('view')
      end
    end

    context 'when the role does not exist' do
      it 'returns 404' do
        get '/api/v1/roles/999999/permissions'
        expect(last_response.status).to eq(404)
      end
    end
  end

  describe 'POST /api/v1/roles/:id/permissions/:permission_id' do
    context 'when the role and permission exist' do
      let(:role_id) { TEST_DB[:roles].insert(name: 'Role') }
      let(:permission) { Permission.create(name: 'view', description: 'View permission') }

      it 'adds the permission to the role' do
        post "/api/v1/roles/#{role_id}/permissions/#{permission.id}"
        expect(last_response.status).to eq(201)
        expect(json_response['data']['name']).to eq('view')
      end

      it 'returns 409 if the permission is already added' do
        role = Role[role_id]
        role.add_permission(permission)
        post "/api/v1/roles/#{role_id}/permissions/#{permission.id}"
        expect(last_response.status).to eq(409)
        expect(json_response['errors']['permission']).to eq('already exists')
      end
    end

    context 'when the role does not exist' do
      let(:permission) { Permission.create(name: 'view', description: 'View permission') }

      it 'returns 404' do
        post "/api/v1/roles/999999/permissions/#{permission.id}"
        expect(last_response.status).to eq(404)
      end
    end

    context 'when the permission does not exist' do
      let(:role_id) { TEST_DB[:roles].insert(name: 'Role') }

      it 'returns 404' do
        post "/api/v1/roles/#{role_id}/permissions/999999"
        expect(last_response.status).to eq(404)
      end
    end
  end

  describe 'DELETE /api/v1/roles/:id/permissions/:permission_id' do
    context 'when the role and permission exist' do
      let(:role_id) { TEST_DB[:roles].insert(name: 'Role') }
      let(:permission) { Permission.create(name: 'view', description: 'View permission') }

      before do
        role = Role[role_id]
        role.add_permission(permission)
      end

      it 'removes the permission from the role' do
        delete "/api/v1/roles/#{role_id}/permissions/#{permission.id}"
        expect(last_response.status).to eq(204)
        expect(Role[role_id].permissions).not_to include(permission)
      end

      it 'returns 404 if the permission is not associated with the role' do
        role = Role[role_id]
        role.remove_permission(permission)
        delete "/api/v1/roles/#{role_id}/permissions/#{permission.id}"
        expect(last_response.status).to eq(404)
        expect(json_response['errors']['permission']).to eq('not found')
      end
    end

    context 'when the role does not exist' do
      let(:permission) { Permission.create(name: 'view', description: 'View permission') }

      it 'returns 404' do
        delete "/api/v1/roles/999999/permissions/#{permission.id}"
        expect(last_response.status).to eq(404)
      end
    end

    context 'when the permission does not exist' do
      let(:role_id) { TEST_DB[:roles].insert(name: 'Role') }

      it 'returns 404' do
        delete "/api/v1/roles/#{role_id}/permissions/999999"
        expect(last_response.status).to eq(404)
      end
    end
  end
end

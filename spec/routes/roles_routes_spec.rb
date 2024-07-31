require 'spec_helper'
require 'roda'
require 'rack/test'
require_relative '../../routes/roles_routes'
require 'json'

RSpec.describe RolesRoutes do
  include Rack::Test::Methods

  let(:app) do
    Class.new(RolesRoutes) do
      # Override the authentication for testing
      def rodauth
        OpenStruct.new(require_authentication: nil)
      end
    end.freeze.app
  end

  let(:json_headers) { { 'CONTENT_TYPE' => 'application/json' } }

  before(:each) do
    TEST_DB[:roles].delete
  end

  def json_response
    JSON.parse(last_response.body)
  end

  describe 'GET /roles' do
    before do
      TEST_DB[:roles].multi_insert([
                                     { name: 'Role 1', description: 'Role 1' },
                                     { name: 'Role 2', description: 'Role 2' }
                                   ])
    end

    it 'returns all roles' do
      get '/roles'
      expect(last_response.status).to eq(200)
      expect(json_response['data'].length).to eq(2)
    end
  end

  describe 'GET /roles/:id' do
    context 'when the role exists' do
      let(:role_id) { TEST_DB[:roles].insert(name: 'Test Role') }

      it 'returns a specific role' do
        get "/roles/#{role_id}"
        expect(last_response.status).to eq(200)
        expect(json_response['data']['name']).to eq('Test Role')
      end
    end

    context 'when the role does not exist' do
      it 'returns 404' do
        get '/roles/999999'
        expect(last_response.status).to eq(404)
      end
    end
  end

  describe 'POST /roles' do
    context 'with valid params' do
      let(:valid_params) { { role: { name: 'New Role', description: 'New Role' } }.to_json }

      it 'creates a new role' do
        post '/roles', valid_params, json_headers
        expect(last_response.status).to eq(201)
        expect(json_response['data']['name']).to eq('New Role')
      end
    end

    context 'with invalid params' do
      let(:invalid_params) { { role: { name: '' } }.to_json }

      it 'returns errors' do
        post '/roles', invalid_params, json_headers
        expect(last_response.status).to eq(422)
      end
    end
  end

  describe 'DELETE /roles/:id' do
    context 'when the role exists' do
      let(:role_id) { TEST_DB[:roles].insert(name: 'Role to Delete') }

      it 'deletes the role' do
        delete "/roles/#{role_id}"
        expect(last_response.status).to eq(200)
        expect(TEST_DB[:roles][id: role_id]).to be_nil
      end
    end

    context 'when the role does not exist' do
      it 'returns 404' do
        delete '/roles/999999'
        expect(last_response.status).to eq(404)
      end
    end
  end
end

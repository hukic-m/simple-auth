require 'spec_helper'
require 'roda'
require 'rack/test'
require_relative '../../routes/roles_routes'
require 'byebug'
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

  # Clean the database before each test
  before(:each) do
    TEST_DB[:roles].delete
  end

  describe 'GET /roles' do
    it 'returns all roles' do
      TEST_DB[:roles].multi_insert([{ name: 'Role 1', description: 'Role 1' },
                                    { name: 'Role 2', description: 'Role 2' }])

      get '/roles'

      expect(last_response.status).to eq(200)
      json_response = JSON.parse(last_response.body)
      expect(json_response['data'].length).to eq(2)
    end
  end

  describe 'GET /roles/:id' do
    it 'returns a specific role' do
      role_id = TEST_DB[:roles].insert(name: 'Test Role')

      get "/roles/#{role_id}"

      expect(last_response.status).to eq(200)
      json_response = JSON.parse(last_response.body)
      expect(json_response['data']['name']).to eq('Test Role')
    end

    it 'returns 404 for non-existent role' do
      get '/roles/999999'

      expect(last_response.status).to eq(404)
    end
  end

  describe 'POST /roles' do
    it 'creates a new role with valid params' do
      post('/roles', { role: { name: 'New Role', description: 'New Role' } }.to_json,
           'CONTENT_TYPE' => 'application/json')
      expect(last_response.status).to eq(201)
      json_response = JSON.parse(last_response.body)
      expect(json_response['data']['name']).to eq('New Role')
    end

    it 'returns errors with invalid params' do
      post '/roles', { name: '' }.to_json, { 'CONTENT_TYPE' => 'application/json' }

      expect(last_response.status).to eq(422)
    end
  end

  describe 'DELETE /roles/:id' do
    it 'deletes an existing role' do
      role_id = TEST_DB[:roles].insert(name: 'Role to Delete')

      delete "/roles/#{role_id}"

      expect(last_response.status).to eq(200)
      expect(TEST_DB[:roles][id: role_id]).to be_nil
    end

    it 'returns 404 for non-existent role' do
      delete '/roles/999999'

      expect(last_response.status).to eq(404)
    end
  end
end

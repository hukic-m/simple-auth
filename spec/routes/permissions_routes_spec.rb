require 'spec_helper'
require 'roda'
require 'rack/test'
require 'json'
require_relative '../../app'

RSpec.describe 'Permissions routes' do
  include Rack::Test::Methods

  def app
    SimpleAuth.app
  end

  let(:json_headers) { { 'CONTENT_TYPE' => 'application/json' } }

  before do
    allow_any_instance_of(RodauthApp).to receive(:require_authentication).and_return(true)
  end

  let(:valid_params) { { 'permission' => { 'name' => 'Test Permission', 'description' => 'A test permission' } } }
  let(:invalid_params) { { 'permission' => { 'name' => '', 'description' => 'Invalid permission' } } }

  before do
    # Mock authentication
    allow_any_instance_of(RodauthApp).to receive(:require_authentication).and_return(true)
  end

  # Custom method to convert hash keys to strings
  def stringify_keys(hash)
    hash.transform_keys(&:to_s)
  end

  describe 'GET /permissions' do
    it 'returns all permissions' do
      permissions = [
        Permission.create(name: 'Permission 1', description: 'Description 1'),
        Permission.create(name: 'Permission 2', description: 'Description 2')
      ]

      get '/v1/permissions'

      expect(last_response.status).to eq(200)
      expect(JSON.parse(last_response.body)).to eq(permissions.map { |p| stringify_keys(p.to_hash) })
    end
  end

  describe 'POST /permissions' do
    context 'with valid parameters' do
      it 'creates a new permission' do
        expect do
          post '/v1/permissions', valid_params
        end.to change(Permission, :count).by(1)

        expect(last_response.status).to eq(200)
        expect(JSON.parse(last_response.body)['name']).to eq('Test Permission')
      end
    end

    context 'with invalid parameters' do
      it 'returns validation errors' do
        post '/v1/permissions', invalid_params

        expect(last_response.status).to eq(422)
        expect(JSON.parse(last_response.body)).to have_key('errors')
      end
    end
  end

  describe 'GET /permissions/:id' do
    let(:permission) { Permission.create(name: 'Existing Permission', description: 'An existing permission') }

    it 'returns the specified permission' do
      get "/v1/permissions/#{permission.id}"

      expect(last_response.status).to eq(200)
      expect(JSON.parse(last_response.body)).to eq(stringify_keys(permission.to_hash))
    end

    it 'returns 404 for non-existent permission' do
      get '/v1/permissions/999999'

      expect(last_response.status).to eq(404)
      expect(JSON.parse(last_response.body)).to have_key('error')
    end
  end

  describe 'PATCH /permissions/:id' do
    let(:permission) { Permission.create(name: 'Existing Permission', description: 'An existing permission') }

    context 'with valid parameters' do
      it 'updates the permission' do
        patch "/v1/permissions/#{permission.id}",
              { 'permission' => { 'name' => 'Updated Permission', 'description' => permission.description } }

        expect(last_response.status).to eq(200)
        expect(JSON.parse(last_response.body)['name']).to eq('Updated Permission')
      end
    end

    context 'with invalid parameters' do
      it 'returns validation errors' do
        patch "/v1/permissions/#{permission.id}", { 'permission' => { 'name' => '' } }

        expect(last_response.status).to eq(422)
        expect(JSON.parse(last_response.body)).to have_key('errors')
      end
    end
  end

  describe 'DELETE /permissions/:id' do
    let!(:permission) { Permission.create(name: 'To Be Deleted', description: 'A permission to be deleted') }

    it 'deletes the specified permission' do
      expect do
        delete "/v1/permissions/#{permission.id}"
      end.to change(Permission, :count).by(-1)

      expect(last_response.status).to eq(200)
      expect(JSON.parse(last_response.body)).to have_key('message')
    end
  end
end

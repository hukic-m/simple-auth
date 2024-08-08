require 'spec_helper'
require 'json'
require_relative '../../lib/auth_helpers'

RSpec.describe AuthHelpers do
  let(:dummy_class) { Class.new { include AuthHelpers } }
  let(:instance) { dummy_class.new }
  let(:request) { double('request', path_info: '/accounts/1') }
  let(:response) { double('response', status: nil, write: nil) }

  before do
    allow(instance).to receive(:request).and_return(request)
    allow(instance).to receive(:response).and_return(response)
    allow(response).to receive(:status=)
    allow(response).to receive(:write)
    allow(request).to receive(:halt)
    ENV['ROLE_ADMIN'] = 'admin'
  end

  describe '#require_role' do
    before { instance.instance_variable_set(:@jwt_payload, { 'roles' => %w[admin user] }) }

    it 'raises an error if required_roles is not an array' do
      expect { instance.require_role('admin') }.to raise_error(ArgumentError)
    end

    it 'returns true if the user has one of the required roles' do
      expect(instance.require_role(['admin'])).to be true
    end

    it 'denies access if the user does not have any of the required roles' do
      expect(response).to receive(:status=).with(403)
      expect(response).to receive(:write).with({ error: 'Forbidden' }.to_json)
      expect(request).to receive(:halt)
      instance.require_role(['guest'])
    end
  end

  describe '#require_permission' do
    before { instance.instance_variable_set(:@jwt_payload, { 'permissions' => %w[read write] }) }

    it 'raises an error if required_permissions is not an array' do
      expect { instance.require_permission('read') }.to raise_error(ArgumentError)
    end

    it 'returns true if the user has one of the required permissions' do
      expect(instance.require_permission(['read'])).to be true
    end

    it 'denies access if the user does not have any of the required permissions' do
      expect(response).to receive(:status=).with(403)
      expect(response).to receive(:write).with({ error: 'Forbidden' }.to_json)
      expect(request).to receive(:halt)
      instance.require_permission(['execute'])
    end
  end

  describe '#account_middleware' do
    before { instance.instance_variable_set(:@jwt_payload, { 'account_id' => 1, 'roles' => ['admin'] }) }

    it 'returns true if the user is accessing their own account' do
      expect(instance.account_middleware).to be true
    end

    it 'returns true if the user is an admin' do
      allow(instance).to receive(:require_role).with(['admin']).and_return(true)
      expect(instance.account_middleware).to be true
    end
  end
end

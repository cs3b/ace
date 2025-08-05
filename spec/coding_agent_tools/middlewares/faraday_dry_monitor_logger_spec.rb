# frozen_string_literal: true

require 'spec_helper'
require 'webmock/rspec'

RSpec.describe CodingAgentTools::Middlewares::FaradayDryMonitorLogger do
  let(:app) { double('app') }
  let(:notifications) { CodingAgentTools::Notifications.notifications }
  let(:middleware) { described_class.new(app, notifications_instance: notifications, event_namespace: :test) }
  let(:request_env) { double('request_env') }
  let(:response) { double('response') }

  before do
    # Clear any existing subscriptions
    notifications.instance_variable_set(:@subscribers, {})
  end

  describe '#initialize' do
    it 'registers events with the notifications instance' do
      expect(notifications).to receive(:register_event).with('test.request.coding_agent_tools')
      expect(notifications).to receive(:register_event).with('test.response.coding_agent_tools')

      described_class.new(app, notifications_instance: notifications, event_namespace: :test)
    end

    it 'raises ArgumentError for invalid notifications instance' do
      expect do
        described_class.new(app, notifications_instance: nil)
      end.to raise_error(ArgumentError, 'notifications_instance must be a Dry::Monitor::Notifications compatible object')
    end

    it 'uses default event namespace when not provided' do
      expect(notifications).to receive(:register_event).with('http_client.request.coding_agent_tools')
      expect(notifications).to receive(:register_event).with('http_client.response.coding_agent_tools')

      described_class.new(app, notifications_instance: notifications)
    end
  end

  describe '#call' do
    let(:url) { double('url', to_s: 'https://example.com/api') }
    let(:request_headers) { { 'Content-Type' => 'application/json' } }
    let(:response_headers) { { 'Content-Type' => 'application/json' } }

    before do
      allow(request_env).to receive(:method).and_return(:post)
      allow(request_env).to receive(:url).and_return(url)
      allow(request_env).to receive(:request_headers).and_return(request_headers)
      allow(response).to receive(:status).and_return(200)
      allow(response).to receive(:headers).and_return(response_headers)

      # Initialize middleware to register events
      middleware
    end

    context 'when request succeeds' do
      before do
        allow(app).to receive(:call).with(request_env).and_return(response)
      end

      it 'publishes request and response events' do
        request_events = []
        response_events = []

        notifications.subscribe('test.request.coding_agent_tools') { |event| request_events << event }
        notifications.subscribe('test.response.coding_agent_tools') { |event| response_events << event }

        result = middleware.call(request_env)

        expect(result).to eq(response)
        expect(request_events.size).to eq(1)
        expect(response_events.size).to eq(1)

        # Check request event payload
        request_event = request_events.first
        expect(request_event.payload[:method]).to eq(:post)
        expect(request_event.payload[:url]).to eq('https://example.com/api')
        expect(request_event.payload[:headers]).to eq(request_headers)

        # Check response event payload
        response_event = response_events.first
        expect(response_event.payload[:method]).to eq(:post)
        expect(response_event.payload[:url]).to eq('https://example.com/api')
        expect(response_event.payload[:status]).to eq(200)
        expect(response_event.payload[:duration_ms]).to be_a(Float)
        expect(response_event.payload[:response_headers]).to eq(response_headers)
        expect(response_event.payload[:error_class]).to be_nil
      end

      it 'measures request duration' do
        response_events = []
        notifications.subscribe('test.response.coding_agent_tools') { |event| response_events << event }

        middleware.call(request_env)

        response_event = response_events.first
        expect(response_event.payload[:duration_ms]).to be > 0
        expect(response_event.payload[:duration_ms]).to be < 1000 # Should be very fast for a test
      end
    end

    context 'when request fails' do
      let(:error) { StandardError.new('Connection failed') }

      before do
        allow(app).to receive(:call).with(request_env).and_raise(error)
      end

      it 'publishes request event and response event with error info' do
        request_events = []
        response_events = []

        notifications.subscribe('test.request.coding_agent_tools') { |event| request_events << event }
        notifications.subscribe('test.response.coding_agent_tools') { |event| response_events << event }

        expect { middleware.call(request_env) }.to raise_error(StandardError, 'Connection failed')

        expect(request_events.size).to eq(1)
        expect(response_events.size).to eq(1)

        # Check response event payload includes error info
        response_event = response_events.first
        expect(response_event.payload[:status]).to be_nil
        expect(response_event.payload[:error_class]).to eq('StandardError')
        expect(response_event.payload[:response_headers]).to eq({})
      end

      it 're-raises the original error' do
        expect { middleware.call(request_env) }.to raise_error(StandardError, 'Connection failed')
      end
    end
  end

  describe 'middleware registration' do
    it 'registers the middleware with Faraday' do
      expect(Faraday::Middleware.registered_middleware).to have_key(:faraday_dry_monitor_logger)
    end

    it 'can be used in Faraday connection' do
      stub_request(:get, 'https://example.com/test')
        .to_return(status: 200, body: '{"success": true}', headers: { 'Content-Type' => 'application/json' })

      # Pre-register events to allow subscription
      notifications.register_event('test.request.coding_agent_tools')
      notifications.register_event('test.response.coding_agent_tools')

      connection = Faraday.new(url: 'https://example.com') do |faraday|
        faraday.use :faraday_dry_monitor_logger,
          notifications_instance: notifications,
          event_namespace: :test
        faraday.adapter :net_http
      end

      response_events = []
      notifications.subscribe('test.response.coding_agent_tools') { |event| response_events << event }

      response = connection.get('/test')

      expect(response.status).to eq(200)
      expect(response_events.size).to eq(1)
      expect(response_events.first.payload[:method]).to eq(:get)
      expect(response_events.first.payload[:url]).to eq('https://example.com/test')
      expect(response_events.first.payload[:status]).to eq(200)
    end
  end
end

# frozen_string_literal: true

require "spec_helper"
require "coding_agent_tools/atoms/http_client"
require "webmock/rspec"

RSpec.describe CodingAgentTools::Atoms::HTTPClient do
  let(:client) { described_class.new }
  let(:custom_client) { described_class.new(timeout: 60, open_timeout: 20) }
  let(:test_url) { "https://api.example.com" }

  # Helper method to create a fast client for testing retry/timeout behavior
  def fast_client(retry_config = {})
    default_fast_config = {
      max_attempts: 2,
      base_delay: 0.001
    }
    described_class.new(retry_config: default_fast_config.merge(retry_config))
  end

  # Helper to mock sleep for fast test execution
  def mock_sleep_delays
    allow_any_instance_of(CodingAgentTools::Molecules::RetryMiddleware).to receive(:sleep)
  end

  describe "#initialize" do
    it "uses default timeout values when no options provided" do
      expect(client.instance_variable_get(:@timeout)).to eq(30)
      expect(client.instance_variable_get(:@open_timeout)).to eq(10)
    end

    it "accepts custom timeout values" do
      expect(custom_client.instance_variable_get(:@timeout)).to eq(60)
      expect(custom_client.instance_variable_get(:@open_timeout)).to eq(20)
    end
  end

  describe "#get" do
    before do
      stub_request(:get, "#{test_url}/endpoint")
        .with(headers: {"Accept" => "*/*"})
        .to_return(status: 200, body: "Success", headers: {"Content-Type" => "text/plain"})
    end

    it "performs a GET request successfully" do
      response = client.get("#{test_url}/endpoint")
      expect(response.status).to eq(200)
      expect(response.body).to eq("Success")
    end

    it "includes custom headers in the request" do
      stub_request(:get, "#{test_url}/endpoint")
        .with(headers: {"Accept" => "*/*", "Authorization" => "Bearer token123"})
        .to_return(status: 200, body: "Authorized")

      response = client.get("#{test_url}/endpoint", headers: {"Authorization" => "Bearer token123"})
      expect(response.status).to eq(200)
      expect(response.body).to eq("Authorized")
    end

    it "handles connection errors" do
      mock_sleep_delays

      stub_request(:get, "#{test_url}/endpoint").to_raise(Faraday::ConnectionFailed)

      expect do
        client.get("#{test_url}/endpoint")
      end.to raise_error(Faraday::ConnectionFailed)
    end

    it "handles 404 responses" do
      stub_request(:get, "#{test_url}/not-found")
        .to_return(status: 404, body: "Not Found")

      response = client.get("#{test_url}/not-found")
      expect(response.status).to eq(404)
      expect(response.body).to eq("Not Found")
    end

    it "retries 500 server errors and eventually fails" do
      mock_sleep_delays

      stub_request(:get, "#{test_url}/error")
        .to_return(status: 500, body: "Internal Server Error")
        .times(3) # Should retry 3 times by default

      expect do
        client.get("#{test_url}/error")
      end.to raise_error(CodingAgentTools::Molecules::RetryMiddleware::RetryableError, /Retryable response: 500/)
    end
  end

  describe "#post" do
    context "with string body" do
      before do
        stub_request(:post, "#{test_url}/endpoint")
          .with(body: "raw string data")
          .to_return(status: 201, body: "Created")
      end

      it "sends string body as-is" do
        response = client.post("#{test_url}/endpoint", "raw string data")
        expect(response.status).to eq(201)
        expect(response.body).to eq("Created")
      end
    end

    context "with hash body" do
      let(:request_body) { {name: "Test", value: 123} }

      before do
        stub_request(:post, "#{test_url}/endpoint")
          .with(
            body: '{"name":"Test","value":123}',
            headers: {"Content-Type" => "application/json"}
          )
          .to_return(status: 201, body: '{"id":1,"name":"Test","value":123}')
      end

      it "converts hash to JSON and sets Content-Type" do
        response = client.post("#{test_url}/endpoint", request_body)
        expect(response.status).to eq(201)
        expect(response.body).to include('"name":"Test"')
      end
    end

    it "includes custom headers in the request" do
      stub_request(:post, "#{test_url}/endpoint")
        .with(
          body: "data",
          headers: {"Authorization" => "Bearer token123", "X-Custom" => "value"}
        )
        .to_return(status: 200, body: "Success")

      response = client.post(
        "#{test_url}/endpoint",
        "data",
        headers: {"Authorization" => "Bearer token123", "X-Custom" => "value"}
      )
      expect(response.status).to eq(200)
    end

    it "handles connection errors" do
      mock_sleep_delays

      stub_request(:post, "#{test_url}/endpoint").to_raise(Faraday::ConnectionFailed)

      expect do
        client.post("#{test_url}/endpoint", "data")
      end.to raise_error(Faraday::ConnectionFailed)
    end

    it "handles 400 bad request" do
      stub_request(:post, "#{test_url}/endpoint")
        .to_return(status: 400, body: '{"error":"Invalid request"}')

      response = client.post("#{test_url}/endpoint", {invalid: true})
      expect(response.status).to eq(400)
      expect(response.body).to include("Invalid request")
    end

    context "with complex nested hash" do
      let(:complex_body) do
        {
          user: {
            name: "John Doe",
            email: "john@example.com",
            preferences: {
              notifications: true,
              theme: "dark"
            }
          },
          metadata: {
            timestamp: "2024-01-01T00:00:00Z",
            version: 1
          }
        }
      end

      it "properly serializes nested structures" do
        expected_json = JSON.generate(complex_body)

        stub_request(:post, "#{test_url}/users")
          .with(
            body: expected_json,
            headers: {"Content-Type" => "application/json"}
          )
          .to_return(status: 201, body: '{"id":123}')

        response = client.post("#{test_url}/users", complex_body)
        expect(response.status).to eq(201)
      end
    end

    context "with empty body" do
      it "handles empty string body" do
        stub_request(:post, "#{test_url}/endpoint")
          .with(body: "")
          .to_return(status: 204, body: "")

        response = client.post("#{test_url}/endpoint", "")
        expect(response.status).to eq(204)
      end

      it "handles empty hash body" do
        stub_request(:post, "#{test_url}/endpoint")
          .with(
            body: "{}",
            headers: {"Content-Type" => "application/json"}
          )
          .to_return(status: 204, body: "")

        response = client.post("#{test_url}/endpoint", {})
        expect(response.status).to eq(204)
      end
    end
  end

  describe "timeout behavior" do
    it "respects custom timeout settings" do
      mock_sleep_delays
      slow_client = described_class.new(timeout: 0.001, open_timeout: 0.001)

      stub_request(:get, "#{test_url}/slow")
        .to_raise(Faraday::TimeoutError.new("execution expired"))

      expect do
        slow_client.get("#{test_url}/slow")
      end.to raise_error(Faraday::TimeoutError)
    end
  end

  describe "retry behavior", :slow do
    let(:retry_client) { fast_client }

    before do
      mock_sleep_delays
    end

    context "with retryable status codes" do
      it "retries HTTP 429 responses" do
        stub_request(:get, "#{test_url}/rate-limited")
          .to_return(status: 429, body: "Rate limited")
          .then.to_return(status: 200, body: "Success")

        response = retry_client.get("#{test_url}/rate-limited")
        expect(response.status).to eq(200)
        expect(response.body).to eq("Success")
      end

      it "retries HTTP 502 responses" do
        stub_request(:get, "#{test_url}/bad-gateway")
          .to_return(status: 502, body: "Bad Gateway")
          .then.to_return(status: 200, body: "Success")

        response = retry_client.get("#{test_url}/bad-gateway")
        expect(response.status).to eq(200)
        expect(response.body).to eq("Success")
      end

      it "retries HTTP 503 responses" do
        stub_request(:get, "#{test_url}/service-unavailable")
          .to_return(status: 503, body: "Service Unavailable")
          .then.to_return(status: 200, body: "Success")

        response = retry_client.get("#{test_url}/service-unavailable")
        expect(response.status).to eq(200)
        expect(response.body).to eq("Success")
      end

      it "fails after max retries with retryable status codes" do
        stub_request(:get, "#{test_url}/persistent-error")
          .to_return(status: 503, body: "Service Unavailable")
          .times(2) # Should retry up to max_attempts

        expect do
          retry_client.get("#{test_url}/persistent-error")
        end.to raise_error(CodingAgentTools::Molecules::RetryMiddleware::RetryableError)
      end
    end

    context "with non-retryable status codes" do
      it "does not retry HTTP 404 responses" do
        stub_request(:get, "#{test_url}/not-found")
          .to_return(status: 404, body: "Not Found")
          .times(1) # Should only be called once

        response = retry_client.get("#{test_url}/not-found")
        expect(response.status).to eq(404)
        expect(response.body).to eq("Not Found")
      end

      it "does not retry HTTP 401 responses" do
        stub_request(:get, "#{test_url}/unauthorized")
          .to_return(status: 401, body: "Unauthorized")
          .times(1) # Should only be called once

        response = retry_client.get("#{test_url}/unauthorized")
        expect(response.status).to eq(401)
        expect(response.body).to eq("Unauthorized")
      end
    end

    context "with connection errors" do
      it "retries connection failures" do
        stub_request(:get, "#{test_url}/connection-error")
          .to_raise(Faraday::ConnectionFailed)
          .then.to_return(status: 200, body: "Success")

        response = retry_client.get("#{test_url}/connection-error")
        expect(response.status).to eq(200)
        expect(response.body).to eq("Success")
      end

      it "retries timeout errors" do
        stub_request(:get, "#{test_url}/timeout-error")
          .to_raise(Faraday::TimeoutError)
          .then.to_return(status: 200, body: "Success")

        response = retry_client.get("#{test_url}/timeout-error")
        expect(response.status).to eq(200)
        expect(response.body).to eq("Success")
      end

      it "fails after max retries with connection errors" do
        stub_request(:get, "#{test_url}/persistent-connection-error")
          .to_raise(Faraday::ConnectionFailed)
          .times(2) # Should retry up to max_attempts

        expect do
          retry_client.get("#{test_url}/persistent-connection-error")
        end.to raise_error(Faraday::ConnectionFailed)
      end
    end

    context "with POST requests" do
      it "retries POST requests with retryable errors" do
        stub_request(:post, "#{test_url}/retry-post")
          .with(body: "test data")
          .to_return(status: 503, body: "Service Unavailable")
          .then.to_return(status: 201, body: "Created")

        response = retry_client.post("#{test_url}/retry-post", "test data")
        expect(response.status).to eq(201)
        expect(response.body).to eq("Created")
      end
    end

    context "with custom retry configuration" do
      let(:custom_retry_client) do
        fast_client(
          max_attempts: 4,
          retryable_status_codes: [418, 500] # Custom status codes
        )
      end

      it "uses custom retryable status codes" do
        stub_request(:get, "#{test_url}/teapot")
          .to_return(status: 418, body: "I'm a teapot")
          .then.to_return(status: 200, body: "Success")

        response = custom_retry_client.get("#{test_url}/teapot")
        expect(response.status).to eq(200)
        expect(response.body).to eq("Success")
      end

      it "does not retry status codes not in custom list" do
        stub_request(:get, "#{test_url}/bad-gateway")
          .to_return(status: 502, body: "Bad Gateway")
          .times(1) # Should only be called once since 502 not in custom list

        response = custom_retry_client.get("#{test_url}/bad-gateway")
        expect(response.status).to eq(502)
        expect(response.body).to eq("Bad Gateway")
      end
    end
  end

  describe "SSL/TLS handling" do
    it "works with HTTPS URLs" do
      stub_request(:get, "https://secure.example.com/data")
        .to_return(status: 200, body: "Secure data")

      response = client.get("https://secure.example.com/data")
      expect(response.status).to eq(200)
      expect(response.body).to eq("Secure data")
    end
  end

  describe "edge cases" do
    it "handles URLs with query parameters" do
      stub_request(:get, "#{test_url}/search?q=test&limit=10")
        .to_return(status: 200, body: "Results")

      response = client.get("#{test_url}/search?q=test&limit=10")
      expect(response.status).to eq(200)
    end

    it "handles URLs with special characters" do
      encoded_url = "#{test_url}/path%20with%20spaces"
      stub_request(:get, encoded_url)
        .to_return(status: 200, body: "OK")

      response = client.get(encoded_url)
      expect(response.status).to eq(200)
    end

    it "handles large response bodies" do
      large_body = "x" * 10_000
      stub_request(:get, "#{test_url}/large")
        .to_return(status: 200, body: large_body)

      response = client.get("#{test_url}/large")
      expect(response.body.length).to eq(10_000)
    end
  end
end

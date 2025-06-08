# frozen_string_literal: true

require "spec_helper"
require "coding_agent_tools/atoms/http_client"
require "webmock/rspec"

RSpec.describe CodingAgentTools::Atoms::HTTPClient do
  let(:client) { described_class.new }
  let(:custom_client) { described_class.new(timeout: 60, open_timeout: 20) }
  let(:test_url) { "https://api.example.com" }

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

      response = client.get("#{test_url}/endpoint", {"Authorization" => "Bearer token123"})
      expect(response.status).to eq(200)
      expect(response.body).to eq("Authorized")
    end

    it "handles connection errors" do
      stub_request(:get, "#{test_url}/endpoint").to_timeout

      expect {
        client.get("#{test_url}/endpoint")
      }.to raise_error(Faraday::ConnectionFailed)
    end

    it "handles 404 responses" do
      stub_request(:get, "#{test_url}/not-found")
        .to_return(status: 404, body: "Not Found")

      response = client.get("#{test_url}/not-found")
      expect(response.status).to eq(404)
      expect(response.body).to eq("Not Found")
    end

    it "handles 500 server errors" do
      stub_request(:get, "#{test_url}/error")
        .to_return(status: 500, body: "Internal Server Error")

      response = client.get("#{test_url}/error")
      expect(response.status).to eq(500)
      expect(response.body).to eq("Internal Server Error")
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
        {"Authorization" => "Bearer token123", "X-Custom" => "value"}
      )
      expect(response.status).to eq(200)
    end

    it "handles connection errors" do
      stub_request(:post, "#{test_url}/endpoint").to_timeout

      expect {
        client.post("#{test_url}/endpoint", "data")
      }.to raise_error(Faraday::ConnectionFailed)
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
      slow_client = described_class.new(timeout: 0.1, open_timeout: 0.1)

      stub_request(:get, "#{test_url}/slow")
        .to_timeout

      expect {
        slow_client.get("#{test_url}/slow")
      }.to raise_error(Faraday::ConnectionFailed)
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

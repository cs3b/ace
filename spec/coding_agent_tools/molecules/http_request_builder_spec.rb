# frozen_string_literal: true

require "spec_helper"
require "coding_agent_tools/molecules/http_request_builder"
require "webmock/rspec"

RSpec.describe CodingAgentTools::Molecules::HTTPRequestBuilder do
  let(:builder) { described_class.new }
  let(:custom_client) { instance_double(CodingAgentTools::Atoms::HTTPClient) }
  let(:builder_with_custom_client) { described_class.new(client: custom_client) }
  let(:test_url) { "https://api.example.com" }

  describe "#initialize" do
    it "creates a new HTTP client when none provided" do
      expect(builder.instance_variable_get(:@client)).to be_a(CodingAgentTools::Atoms::HTTPClient)
    end

    it "uses provided HTTP client" do
      expect(builder_with_custom_client.instance_variable_get(:@client)).to eq(custom_client)
    end

    it "passes options to HTTP client creation" do
      builder = described_class.new(timeout: 60, open_timeout: 20)
      client = builder.instance_variable_get(:@client)
      expect(client.instance_variable_get(:@timeout)).to eq(60)
      expect(client.instance_variable_get(:@open_timeout)).to eq(20)
    end
  end

  describe "#json_request" do
    context "with GET request" do
      before do
        stub_request(:get, "#{test_url}/users")
          .with(headers: {"Accept" => "application/json"})
          .to_return(
            status: 200,
            body: '{"users": [{"id": 1, "name": "John"}]}',
            headers: {"Content-Type" => "application/json"}
          )
      end

      it "makes a GET request with JSON headers" do
        result = builder.json_request(:get, "#{test_url}/users")

        expect(result[:status]).to eq(200)
        expect(result[:success]).to be true
        expect(result[:body]).to eq({users: [{id: 1, name: "John"}]})
        expect(result[:raw_body]).to eq('{"users": [{"id": 1, "name": "John"}]}')
      end

      it "includes custom headers" do
        stub_request(:get, "#{test_url}/users")
          .with(headers: {
            "Accept" => "application/json",
            "Authorization" => "Bearer token123"
          })
          .to_return(status: 200, body: "{}")

        result = builder.json_request(:get, "#{test_url}/users", headers: {"Authorization" => "Bearer token123"})
        expect(result[:status]).to eq(200)
      end

      it "handles query parameters" do
        stub_request(:get, "#{test_url}/users?page=2&limit=10")
          .to_return(status: 200, body: '{"page": 2}', headers: {"Content-Type" => "application/json"})

        result = builder.json_request(:get, "#{test_url}/users", query: {page: 2, limit: 10})
        expect(result[:body]).to eq({page: 2})
      end
    end

    context "with POST request" do
      let(:request_body) { {name: "John", email: "john@example.com"} }

      before do
        stub_request(:post, "#{test_url}/users")
          .with(
            body: '{"name":"John","email":"john@example.com"}',
            headers: {"Accept" => "application/json", "Content-Type" => "application/json"}
          )
          .to_return(
            status: 201,
            body: '{"id": 1, "name": "John", "email": "john@example.com"}',
            headers: {"Content-Type" => "application/json"}
          )
      end

      it "makes a POST request with JSON body" do
        result = builder.json_request(:post, "#{test_url}/users", body: request_body)

        expect(result[:status]).to eq(201)
        expect(result[:success]).to be true
        expect(result[:body]).to eq({id: 1, name: "John", email: "john@example.com"})
      end
    end

    context "with non-JSON response" do
      before do
        stub_request(:get, "#{test_url}/text")
          .to_return(
            status: 200,
            body: "Plain text response",
            headers: {"Content-Type" => "text/plain"}
          )
      end

      it "returns body as string for non-JSON content" do
        result = builder.json_request(:get, "#{test_url}/text")
        expect(result[:body]).to eq("Plain text response")
        expect(result).not_to have_key(:raw_body)
      end
    end

    context "with json option set to false" do
      before do
        stub_request(:get, "#{test_url}/data")
          .with(headers: {"Accept" => "*/*"})
          .to_return(status: 200, body: "Some data")
      end

      it "does not set JSON headers" do
        result = builder.json_request(:get, "#{test_url}/data", json: false)
        expect(result[:body]).to eq("Some data")
      end
    end

    context "with error responses" do
      it "handles 404 response" do
        stub_request(:get, "#{test_url}/not-found")
          .to_return(status: 404, body: '{"error": "Not found"}', headers: {"Content-Type" => "application/json"})

        result = builder.json_request(:get, "#{test_url}/not-found")
        expect(result[:status]).to eq(404)
        expect(result[:success]).to be false
        expect(result[:body]).to eq({error: "Not found"})
      end

      it "handles 500 server error" do
        stub_request(:get, "#{test_url}/error")
          .to_return(status: 500, body: "Internal Server Error")

        result = builder.json_request(:get, "#{test_url}/error")
        expect(result[:status]).to eq(500)
        expect(result[:success]).to be false
        expect(result[:body]).to eq("Internal Server Error")
      end
    end

    context "with unsupported HTTP method" do
      it "raises ArgumentError" do
        expect {
          builder.json_request(:delete, "#{test_url}/users/1")
        }.to raise_error(ArgumentError, "Unsupported HTTP method: delete")
      end
    end
  end

  describe "#post_json" do
    let(:body) { {message: "Hello"} }

    before do
      stub_request(:post, "#{test_url}/messages")
        .with(
          body: '{"message":"Hello"}',
          headers: {"Accept" => "application/json", "Content-Type" => "application/json"}
        )
        .to_return(status: 201, body: '{"id": 123, "message": "Hello"}', headers: {"Content-Type" => "application/json"})
    end

    it "makes a POST request with JSON body" do
      result = builder.post_json("#{test_url}/messages", body)
      expect(result[:status]).to eq(201)
      expect(result[:body]).to eq({id: 123, message: "Hello"})
    end

    it "includes custom headers" do
      stub_request(:post, "#{test_url}/messages")
        .with(
          headers: {
            "Accept" => "application/json",
            "Content-Type" => "application/json",
            "X-API-Key" => "secret"
          }
        )
        .to_return(status: 201, body: "{}")

      result = builder.post_json("#{test_url}/messages", body, headers: {"X-API-Key" => "secret"})
      expect(result[:status]).to eq(201)
    end
  end

  describe "#get_json" do
    before do
      stub_request(:get, "#{test_url}/data")
        .with(headers: {"Accept" => "application/json"})
        .to_return(status: 200, body: '{"data": "value"}', headers: {"Content-Type" => "application/json"})
    end

    it "makes a GET request" do
      result = builder.get_json("#{test_url}/data")
      expect(result[:status]).to eq(200)
      expect(result[:body]).to eq({data: "value"})
    end

    it "includes query parameters" do
      stub_request(:get, "#{test_url}/data?filter=active&sort=name")
        .to_return(status: 200, body: '{"filtered": true}', headers: {"Content-Type" => "application/json"})

      result = builder.get_json("#{test_url}/data", query: {filter: "active", sort: "name"})
      expect(result[:body]).to eq({filtered: true})
    end

    it "includes custom headers" do
      stub_request(:get, "#{test_url}/data")
        .with(headers: {
          "Accept" => "application/json",
          "Authorization" => "Bearer token"
        })
        .to_return(status: 200, body: "{}")

      result = builder.get_json("#{test_url}/data", headers: {"Authorization" => "Bearer token"})
      expect(result[:status]).to eq(200)
    end
  end

  describe "#raw_request" do
    context "with GET method" do
      it "returns raw Faraday response" do
        stub_request(:get, "#{test_url}/raw")
          .with(headers: {"Custom" => "Header"})
          .to_return(status: 200, body: "Raw response")

        response = builder.raw_request(:get, "#{test_url}/raw", headers: {"Custom" => "Header"})

        expect(response).to be_a(Faraday::Response)
        expect(response.status).to eq(200)
        expect(response.body).to eq("Raw response")
      end
    end

    context "with POST method" do
      it "returns raw Faraday response" do
        stub_request(:post, "#{test_url}/raw")
          .with(body: "Raw body")
          .to_return(status: 201, body: "Created")

        response = builder.raw_request(:post, "#{test_url}/raw", body: "Raw body")

        expect(response).to be_a(Faraday::Response)
        expect(response.status).to eq(201)
        expect(response.body).to eq("Created")
      end
    end

    context "with unsupported method" do
      it "raises ArgumentError" do
        expect {
          builder.raw_request(:put, "#{test_url}/raw")
        }.to raise_error(ArgumentError, "Unsupported HTTP method: put")
      end
    end
  end

  describe "private methods" do


    end

    describe "#build_headers" do
      it "returns JSON headers by default for POST/PUT or with body" do
        # Test case for POST (where Content-Type should be added by default)
        headers_post = builder.send(:build_headers, nil, json: true, method: :post)
        expect(headers_post).to eq({
          "Accept" => "application/json",
          "Content-Type" => "application/json"
        })

        # Test case with a body (where Content-Type should be added by default)
        headers_with_body = builder.send(:build_headers, nil, json: true, body: "data")
        expect(headers_with_body).to eq({
          "Accept" => "application/json",
          "Content-Type" => "application/json"
        })

        # Test case for GET without body (Content-Type should NOT be added by default)
        headers_get = builder.send(:build_headers, nil, json: true, method: :get)
        expect(headers_get).to eq({
          "Accept" => "application/json"
          # No Content-Type
        })
      end

      it "returns empty hash when json is false" do
        headers = builder.send(:build_headers, nil, json: false)
        expect(headers).to eq({})
      end

      it "merges custom headers" do
        custom = {"Authorization" => "Bearer token", "X-Custom" => "value"}
        # Test with method: :post to ensure Content-Type is part of default headers
        headers = builder.send(:build_headers, custom, json: true, method: :post)

        expect(headers).to include(
          "Accept" => "application/json",
          "Content-Type" => "application/json",
          "Authorization" => "Bearer token",
          "X-Custom" => "value"
        )

        # Test with method: :get (no body) to ensure Content-Type is NOT part of default headers
        headers_get = builder.send(:build_headers, custom, json: true, method: :get)
        expect(headers_get).to include(
          "Accept" => "application/json",
          "Authorization" => "Bearer token",
          "X-Custom" => "value"
        )
        expect(headers_get).not_to include("Content-Type")
      end

      it "allows custom headers to override defaults" do
        custom = {"Content-Type" => "text/plain"}
        headers = builder.send(:build_headers, custom, json: true)

        expect(headers["Content-Type"]).to eq("text/plain")
      end
    end

    describe "#parse_response" do
      let(:json_response) do
        double("response",
          status: 200,
          success?: true,
          headers: {"content-type" => "application/json; charset=utf-8"},
          body: '{"key": "value"}')
      end

      let(:text_response) do
        double("response",
          status: 200,
          success?: true,
          headers: {"content-type" => "text/plain"},
          body: "Plain text")
      end

      it "parses JSON response when content-type is JSON" do
        result = builder.send(:parse_response, json_response, json: true)

        expect(result[:status]).to eq(200)
        expect(result[:success]).to be true
        expect(result[:body]).to eq({key: "value"})
        expect(result[:raw_body]).to eq('{"key": "value"}')
      end

      it "returns string body for non-JSON content-type" do
        result = builder.send(:parse_response, text_response, json: true)

        expect(result[:body]).to eq("Plain text")
        expect(result).not_to have_key(:raw_body)
      end

      it "returns string body when json option is false" do
        result = builder.send(:parse_response, json_response, json: false)

        expect(result[:body]).to eq('{"key": "value"}')
        expect(result).not_to have_key(:raw_body)
      end

      it "handles invalid JSON gracefully" do
        invalid_json_response = double("response",
          status: 200,
          success?: true,
          headers: {"content-type" => "application/json"},
          body: "not valid json")

        result = builder.send(:parse_response, invalid_json_response, json: true)
        expect(result[:body]).to be_nil
        expect(result[:raw_body]).to eq("not valid json")
      end
    end
  end

  describe "error handling" do
    it "propagates connection errors from HTTP client" do
      stub_request(:get, "#{test_url}/timeout").to_timeout

      expect {
        builder.get_json("#{test_url}/timeout")
      }.to raise_error(Faraday::ConnectionFailed)
    end

    it "handles malformed URLs" do
      expect {
        builder.get_json("not a valid url")
      }.to raise_error(URI::InvalidURIError)
    end
  end

  describe "integration scenarios" do
    it "handles complex nested JSON responses" do
      complex_response = {
        data: {
          users: [
            {id: 1, name: "John", tags: ["admin", "user"]},
            {id: 2, name: "Jane", tags: ["user"]}
          ],
          metadata: {
            total: 2,
            page: 1
          }
        }
      }

      stub_request(:get, "#{test_url}/complex")
        .to_return(
          status: 200,
          body: complex_response.to_json,
          headers: {"Content-Type" => "application/json"}
        )

      result = builder.get_json("#{test_url}/complex")
      expect(result[:body]).to eq(complex_response)
    end

    it "handles empty responses" do
      stub_request(:post, "#{test_url}/create")
        .to_return(status: 204, body: "")

      result = builder.post_json("#{test_url}/create", {})
      expect(result[:status]).to eq(204)
      expect(result[:body]).to eq("")
    end
  end
end

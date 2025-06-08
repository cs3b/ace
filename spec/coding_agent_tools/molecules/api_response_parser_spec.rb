# frozen_string_literal: true

require "spec_helper"
require "coding_agent_tools/molecules/api_response_parser"

RSpec.describe CodingAgentTools::Molecules::APIResponseParser do
  let(:parser) { described_class.new }

  describe "#parse_response" do
    context "with successful response" do
      let(:response_data) do
        {
          success: true,
          status: 200,
          body: { "data" => "value", "count" => 42 },
          headers: { "content-type" => "application/json" }
        }
      end

      it "returns parsed response with success status" do
        result = parser.parse_response(response_data)

        expect(result[:success]).to be true
        expect(result[:status]).to eq(200)
        expect(result[:data]).to eq({ "data" => "value", "count" => 42 })
        expect(result[:error]).to be_nil
        expect(result[:headers]).to eq({ "content-type" => "application/json" })
      end
    end

    context "with error response" do
      let(:response_data) do
        {
          success: false,
          status: 404,
          body: { "error" => "Resource not found" },
          headers: { "content-type" => "application/json" }
        }
      end

      it "returns parsed response with error details" do
        result = parser.parse_response(response_data)

        expect(result[:success]).to be false
        expect(result[:status]).to eq(404)
        expect(result[:data]).to be_nil
        expect(result[:error]).to include(
          status: 404,
          message: "Not Found",
          details: { error: "Resource not found" }
        )
      end
    end
  end

  describe "#extract_data" do
    context "with successful response" do
      it "extracts hash body" do
        response_data = { success: true, body: { "key" => "value" } }
        expect(parser.extract_data(response_data)).to eq({ "key" => "value" })
      end

      it "extracts array body" do
        response_data = { success: true, body: [1, 2, 3] }
        expect(parser.extract_data(response_data)).to eq([1, 2, 3])
      end

      it "parses JSON string body" do
        response_data = { success: true, body: '{"parsed": true}' }
        expect(parser.extract_data(response_data)).to eq({ parsed: true })
      end

      it "returns raw string if not parseable JSON" do
        response_data = { success: true, body: "plain text" }
        expect(parser.extract_data(response_data)).to eq("plain text")
      end
    end

    context "with failed response" do
      it "returns nil for failed responses" do
        response_data = { success: false, body: { "data" => "value" } }
        expect(parser.extract_data(response_data)).to be_nil
      end
    end
  end

  describe "#extract_error" do
    context "with successful response" do
      it "returns nil" do
        response_data = { success: true, status: 200, body: "data" }
        expect(parser.extract_error(response_data)).to be_nil
      end
    end

    context "with error response" do
      it "extracts error from known status code" do
        response_data = { success: false, status: 401, body: "" }
        error = parser.extract_error(response_data)

        expect(error[:status]).to eq(401)
        expect(error[:message]).to eq("Unauthorized")
      end

      it "handles unknown status codes" do
        response_data = { success: false, status: 418, body: "" }
        error = parser.extract_error(response_data)

        expect(error[:status]).to eq(418)
        expect(error[:message]).to eq("Unknown Error")
      end

      it "extracts error details from hash body" do
        response_data = {
          success: false,
          status: 400,
          body: { "error" => "Invalid input", "code" => "INVALID_INPUT" }
        }
        error = parser.extract_error(response_data)

        expect(error[:details]).to include(
          error: "Invalid input",
          code: "INVALID_INPUT"
        )
      end

      it "extracts error details from JSON string body" do
        response_data = {
          success: false,
          status: 400,
          body: '{"error_message": "Bad request", "error_code": 1001}'
        }
        error = parser.extract_error(response_data)

        expect(error[:details]).to include(
          error_message: "Bad request",
          error_code: 1001
        )
      end

      it "handles non-JSON string error body" do
        response_data = {
          success: false,
          status: 500,
          body: "Internal server error occurred"
        }
        error = parser.extract_error(response_data)

        expect(error[:raw_message]).to eq("Internal server error occurred")
        expect(error[:details]).to be_nil
      end

      it "handles nested error structures" do
        response_data = {
          success: false,
          status: 400,
          body: {
            "error" => {
              "type" => "validation_error",
              "message" => "Invalid parameters",
              "fields" => ["email", "password"]
            }
          }
        }
        error = parser.extract_error(response_data)

        expect(error[:details]).to include(
          error: { # Expect symbolized keys due to processing in extract_error
            type: "validation_error",
            message: "Invalid parameters",
            fields: ["email", "password"]
          },
          type: "validation_error",
          message: "Invalid parameters",
          fields: ["email", "password"]
        )
      end
    end
  end

  describe "#extract_path" do
    let(:response_data) do
      {
        success: true,
        body: {
          "user" => {
            "name" => "John",
            "email" => "john@example.com",
            "tags" => ["admin", "user"]
          },
          "count" => 42
        }
      }
    end

    it "extracts nested values using dot notation" do
      expect(parser.extract_path(response_data, "user.name")).to eq("John")
      expect(parser.extract_path(response_data, "user.email")).to eq("john@example.com")
      expect(parser.extract_path(response_data, "count")).to eq(42)
    end

    it "extracts array elements" do
      expect(parser.extract_path(response_data, "user.tags.0")).to eq("admin")
      expect(parser.extract_path(response_data, "user.tags.1")).to eq("user")
    end

    it "returns nil for non-existent paths" do
      expect(parser.extract_path(response_data, "user.phone")).to be_nil
      expect(parser.extract_path(response_data, "missing.path")).to be_nil
    end

    it "returns nil for failed responses" do
      failed_response = { success: false, body: { "data" => "value" } }
      expect(parser.extract_path(failed_response, "data")).to be_nil
    end
  end

  describe "#rate_limited?" do
    it "returns true for 429 status" do
      response_data = { status: 429 }
      expect(parser.rate_limited?(response_data)).to be true
    end

    it "returns false for other statuses" do
      expect(parser.rate_limited?({ status: 200 })).to be false
      expect(parser.rate_limited?({ status: 404 })).to be false
      expect(parser.rate_limited?({ status: 500 })).to be false
    end
  end

  describe "#extract_rate_limit_info" do
    context "with rate limit headers" do
      let(:response_data) do
        {
          headers: {
            "x-ratelimit-limit" => "100",
            "x-ratelimit-remaining" => "42",
            "x-ratelimit-reset" => "1640995200",
            "retry-after" => "60"
          }
        }
      end

      it "extracts x-ratelimit headers" do
        info = parser.extract_rate_limit_info(response_data)

        expect(info).to eq({
          limit: "100",
          remaining: "42",
          reset: "1640995200",
          retry_after: "60"
        })
      end
    end

    context "with alternative header names" do
      let(:response_data) do
        {
          headers: {
            "ratelimit-limit" => "1000",
            "ratelimit-remaining" => "500",
            "ratelimit-reset" => "1640998800"
          }
        }
      end

      it "extracts alternative header names" do
        info = parser.extract_rate_limit_info(response_data)

        expect(info).to eq({
          limit: "1000",
          remaining: "500",
          reset: "1640998800"
        })
      end
    end

    context "without rate limit headers" do
      it "returns empty hash" do
        response_data = { headers: { "content-type" => "application/json" } }
        expect(parser.extract_rate_limit_info(response_data)).to eq({})
      end

      it "handles missing headers gracefully" do
        response_data = {}
        expect(parser.extract_rate_limit_info(response_data)).to eq({})
      end
    end
  end

  describe "#validate_response" do
    let(:response_data) do
      {
        success: true,
        body: {
          "user" => {
            "id" => 123,
            "name" => "John",
            "profile" => {
              "email" => "john@example.com"
            }
          },
          "status" => "active"
        }
      }
    end

    it "returns true when all required fields present" do
      required_fields = ["user.id", "user.name", "status"]
      expect(parser.validate_response(response_data, required_fields)).to be true
    end

    it "returns true for deeply nested fields" do
      required_fields = ["user.profile.email"]
      expect(parser.validate_response(response_data, required_fields)).to be true
    end

    it "returns false when required field missing" do
      required_fields = ["user.id", "user.phone"]
      expect(parser.validate_response(response_data, required_fields)).to be false
    end

    it "returns false for failed responses" do
      failed_response = { success: false, body: { "user" => { "id" => 123 } } }
      expect(parser.validate_response(failed_response, ["user.id"])).to be false
    end

    it "handles empty required fields" do
      expect(parser.validate_response(response_data, [])).to be true
    end
  end

  describe "#transform_response" do
    let(:response_data) do
      {
        success: true,
        body: {
          "data" => {
            "user" => {
              "first_name" => "John",
              "last_name" => "Doe",
              "contact" => {
                "email" => "john.doe@example.com",
                "phone" => "+1234567890"
              }
            },
            "metadata" => {
              "created_at" => "2024-01-01",
              "version" => 2
            }
          }
        }
      }
    end

    it "transforms response using mapping" do
      mapping = {
        name: "data.user.first_name",
        surname: "data.user.last_name",
        email: "data.user.contact.email",
        created: "data.metadata.created_at"
      }

      result = parser.transform_response(response_data, mapping)

      expect(result).to eq({
        name: "John",
        surname: "Doe",
        email: "john.doe@example.com",
        created: "2024-01-01"
      })
    end

    it "omits missing fields" do
      mapping = {
        name: "data.user.first_name",
        missing: "data.user.missing_field"
      }

      result = parser.transform_response(response_data, mapping)

      expect(result).to eq({ name: "John" })
      expect(result).not_to have_key(:missing)
    end

    it "returns empty hash for failed responses" do
      failed_response = { success: false, body: { "data" => { "value" => 123 } } }
      mapping = { value: "data.value" }

      result = parser.transform_response(failed_response, mapping)

      expect(result).to eq({})
    end

    it "handles empty mapping" do
      result = parser.transform_response(response_data, {})
      expect(result).to eq({})
    end
  end

  describe "error status codes" do
    it "has correct mappings for common HTTP error codes" do
      expect(described_class::ERROR_STATUS_CODES[400]).to eq("Bad Request")
      expect(described_class::ERROR_STATUS_CODES[401]).to eq("Unauthorized")
      expect(described_class::ERROR_STATUS_CODES[403]).to eq("Forbidden")
      expect(described_class::ERROR_STATUS_CODES[404]).to eq("Not Found")
      expect(described_class::ERROR_STATUS_CODES[429]).to eq("Too Many Requests")
      expect(described_class::ERROR_STATUS_CODES[500]).to eq("Internal Server Error")
      expect(described_class::ERROR_STATUS_CODES[502]).to eq("Bad Gateway")
      expect(described_class::ERROR_STATUS_CODES[503]).to eq("Service Unavailable")
    end
  end

  describe "edge cases" do
    it "handles nil body gracefully" do
      response_data = { success: true, body: nil }
      expect(parser.extract_data(response_data)).to be_nil
    end

    it "handles empty string body" do
      response_data = { success: false, status: 500, body: "" }
      error = parser.extract_error(response_data)

      expect(error[:details]).to be_nil
      expect(error[:raw_message]).to be_nil
    end

    it "handles malformed JSON in error body" do
      response_data = { success: false, status: 500, body: '{"invalid": json}' }
      error = parser.extract_error(response_data)

      expect(error[:raw_message]).to eq('{"invalid": json}')
    end
  end
end

# frozen_string_literal: true

require_relative '../atoms/json_formatter'

module CodingAgentTools
  module Molecules
    # APIResponseParser handles parsing and extracting data from API responses
    # This is a molecule - it composes the JSONFormatter atom
    class APIResponseParser
      # Common API error status codes
      ERROR_STATUS_CODES = {
        400 => 'Bad Request',
        401 => 'Unauthorized',
        403 => 'Forbidden',
        404 => 'Not Found',
        429 => 'Too Many Requests',
        500 => 'Internal Server Error',
        502 => 'Bad Gateway',
        503 => 'Service Unavailable'
      }.freeze

      # Parse a raw API response
      # @param response_data [Hash] Response data from HTTPRequestBuilder
      # @return [Hash] Parsed response with extracted data
      def parse_response(response_data)
        {
          success: response_data[:success],
          status: response_data[:status],
          data: extract_data(response_data),
          error: extract_error(response_data),
          headers: response_data[:headers]
        }
      end

      # Extract data from successful response
      # @param response_data [Hash] Response data
      # @return [Hash, Array, String, nil] Extracted data
      def extract_data(response_data)
        return nil unless response_data[:success]

        body = response_data[:body]

        # If body is already parsed (hash or array), return it
        return body if body.is_a?(Hash) || body.is_a?(Array)

        # Try to parse as JSON if it's a string
        if body.is_a?(String)
          parsed = Atoms::JSONFormatter.safe_parse(body, symbolize_names: true)
          return parsed if parsed
        end

        # Return raw body if can't parse
        body
      end

      # Extract error information from failed response
      # @param response_data [Hash] Response data
      # @return [Hash, nil] Error information or nil if successful
      def extract_error(response_data)
        return nil if response_data[:success]

        error = {
          status: response_data[:status],
          message: ERROR_STATUS_CODES[response_data[:status]] || 'Unknown Error'
        }

        # Try to extract error details from response body
        effective_body = nil
        if response_data[:body].is_a?(Hash)
          # To ensure consistent key symbolization, convert the hash to a JSON string and re-parse it.
          # This handles cases where the input hash might have string keys.
          begin
            json_string = Atoms::JSONFormatter.compact(response_data[:body])
            effective_body = Atoms::JSONFormatter.safe_parse(json_string, symbolize_names: true)
          rescue
            # If conversion to JSON string fails (e.g., body contains non-serializable objects),
            # try a shallow symbolization as a fallback. This might not handle nested string keys.
            effective_body = response_data[:body].transform_keys do |k|
              k.is_a?(String) ? k.to_sym : k
            rescue
              k
            end
          end
        elsif response_data[:body].is_a?(String) && !response_data[:body].empty?
          effective_body = Atoms::JSONFormatter.safe_parse(response_data[:body], symbolize_names: true)
        end

        if effective_body
          error[:details] = extract_error_details(effective_body)
        elsif response_data[:body].is_a?(String) && !response_data[:body].empty? # Not nil/empty, but not parsable JSON
          error[:raw_message] = response_data[:body]
          # else body is nil or not a hash/string, no details to extract beyond status/message
        end

        error
      end

      # Extract specific data using a path
      # @param response_data [Hash] Response data
      # @param path [String] Dot-separated path to extract
      # @return [Object, nil] Extracted value or nil
      def extract_path(response_data, path)
        data = extract_data(response_data)
        return nil unless data

        Atoms::JSONFormatter.extract_path(data, path)
      end

      # Check if response indicates rate limiting
      # @param response_data [Hash] Response data
      # @return [Boolean] True if rate limited
      def rate_limited?(response_data)
        response_data[:status] == 429
      end

      # Extract rate limit information from headers
      # @param response_data [Hash] Response data
      # @return [Hash] Rate limit information
      def extract_rate_limit_info(response_data)
        headers = response_data[:headers] || {}

        {
          limit: headers['x-ratelimit-limit'] || headers['ratelimit-limit'],
          remaining: headers['x-ratelimit-remaining'] || headers['ratelimit-remaining'],
          reset: headers['x-ratelimit-reset'] || headers['ratelimit-reset'],
          retry_after: headers['retry-after']
        }.compact
      end

      # Validate response against expected schema
      # @param response_data [Hash] Response data
      # @param required_fields [Array<String>] Required field paths
      # @return [Boolean] True if all required fields present
      def validate_response(response_data, required_fields)
        data = extract_data(response_data)
        return false unless data

        required_fields.all? do |field_path|
          !Atoms::JSONFormatter.extract_path(data, field_path).nil?
        end
      end

      # Transform response data using a mapping
      # @param response_data [Hash] Response data
      # @param mapping [Hash] Field mapping (output_key => input_path)
      # @return [Hash] Transformed data
      def transform_response(response_data, mapping)
        data = extract_data(response_data)
        return {} unless data

        mapping.each_with_object({}) do |(output_key, input_path), result|
          value = Atoms::JSONFormatter.extract_path(data, input_path)
          result[output_key] = value unless value.nil?
        end
      end

      private

      # Extract error details from parsed error response
      # @param body [Hash] Parsed response body
      # @return [Hash] Error details
      def extract_error_details(body)
        details = {}

        # Common error field names across different APIs
        error_fields = %i[error errors message error_message description error_description code error_code type fields] # Ensure all potential fields are listed

        error_fields.each do |field|
          details[field] = body[field] if body.key?(field) # Use body.key? to avoid issues with falsey values
        end

        # Handle nested error structures, specifically if :error itself contains a hash of details
        # The spec expects these nested details to be merged into the main `details` hash,
        # AND for the original :error structure to be preserved if it was a hash.
        nested_error_content = body[:error]
        if nested_error_content.is_a?(Hash)
          # Ensure original :error key points to the (potentially symbolized) nested hash
          details[:error] = nested_error_content
          # Merge the contents of the nested error hash into the main details hash
          # Keep original if key conflict, though body[field] already set it
          details.merge!(nested_error_content) do |_key, old_val, _new_val|
            old_val
          end
        end

        details.compact! # Remove keys with nil values
        details
      end
    end
  end
end

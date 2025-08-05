# frozen_string_literal: true

# Custom RSpec matchers for HTTP-related assertions
RSpec::Matchers.define :be_successful_http_response do
  match do |actual|
    return false unless actual.respond_to?(:status)

    @status = actual.status
    (200..299).cover?(@status)
  end

  failure_message do |actual|
    if actual.respond_to?(:status)
      "expected HTTP status to be successful (2xx), but got #{@status}"
    else
      "expected object to respond to :status method, but it doesn't"
    end
  end

  failure_message_when_negated do |_actual|
    "expected HTTP status not to be successful (2xx), but got #{@status}"
  end
end

RSpec::Matchers.define :have_http_status do |expected_status|
  match do |actual|
    return false unless actual.respond_to?(:status)

    @actual_status = actual.status
    @actual_status == expected_status
  end

  failure_message do |_actual|
    "expected HTTP status to be #{expected_status}, but got #{@actual_status}"
  end

  failure_message_when_negated do |_actual|
    "expected HTTP status not to be #{expected_status}, but it was"
  end
end

RSpec::Matchers.define :have_http_header do |header_name, expected_value = nil|
  match do |actual|
    return false unless actual.respond_to?(:headers)

    @headers = actual.headers
    @header_name = header_name.to_s.downcase

    # Check if header exists
    header_exists = @headers.keys.any? { |key| key.to_s.downcase == @header_name }
    return false unless header_exists

    # If no expected value specified, just check existence
    return true if expected_value.nil?

    # Find the actual header value
    @actual_value = @headers.find { |key, _| key.to_s.downcase == @header_name }&.last

    case expected_value
    when Regexp
      expected_value.match?(@actual_value.to_s)
    else
      @actual_value.to_s == expected_value.to_s
    end
  end

  failure_message do |actual|
    if actual.respond_to?(:headers)
      if expected_value.nil?
        "expected response to have header '#{header_name}', but it was missing"
      else
        "expected header '#{header_name}' to be '#{expected_value}', but got '#{@actual_value}'"
      end
    else
      "expected object to respond to :headers method, but it doesn't"
    end
  end

  failure_message_when_negated do |_actual|
    if expected_value.nil?
      "expected response not to have header '#{header_name}', but it was present"
    else
      "expected header '#{header_name}' not to be '#{expected_value}', but it was"
    end
  end
end

RSpec::Matchers.define :have_content_type do |expected_type|
  match do |actual|
    return false unless actual.respond_to?(:headers)

    @headers = actual.headers
    content_type_header = @headers.find { |key, _| key.to_s.downcase == 'content-type' }

    return false unless content_type_header

    @actual_content_type = content_type_header.last
    @actual_content_type.to_s.include?(expected_type.to_s)
  end

  failure_message do |_actual|
    if @actual_content_type
      "expected Content-Type to include '#{expected_type}', but got '#{@actual_content_type}'"
    else
      'expected response to have Content-Type header, but it was missing'
    end
  end

  failure_message_when_negated do |_actual|
    "expected Content-Type not to include '#{expected_type}', but got '#{@actual_content_type}'"
  end
end

RSpec::Matchers.define :have_json_response do
  match do |actual|
    # Check if it has JSON content type
    return false unless actual.respond_to?(:headers) && actual.respond_to?(:body)

    @headers = actual.headers
    content_type_header = @headers.find { |key, _| key.to_s.downcase == 'content-type' }

    if content_type_header
      @content_type = content_type_header.last
      return false unless @content_type.to_s.include?('application/json')
    end

    # Check if body is valid JSON
    @body = actual.body
    return false if @body.nil? || @body.empty?

    begin
      JSON.parse(@body)
      true
    rescue JSON::ParserError
      false
    end
  end

  failure_message do |_actual|
    if @content_type && !@content_type.include?('application/json')
      "expected Content-Type to be 'application/json', but got '#{@content_type}'"
    elsif @body.nil? || @body.empty?
      'expected response to have a body, but it was empty'
    else
      'expected response body to be valid JSON, but it failed to parse'
    end
  end

  failure_message_when_negated do |_actual|
    'expected response not to be JSON, but it was valid JSON with correct Content-Type'
  end
end

RSpec::Matchers.define :include_error_message do |expected_message = nil|
  match do |actual|
    @body = if actual.respond_to?(:body)
      actual.body
    else
      actual.to_s
    end

    # Try to parse as JSON first
    begin
      @parsed_body = JSON.parse(@body)

      # Look for common error message fields
      error_fields = ['error', 'message', 'error_message', 'msg', 'detail', 'details']
      @found_messages = []

      error_fields.each do |field|
        if @parsed_body.key?(field)
          @found_messages << @parsed_body[field]
        end
      end

      # Also check nested error objects
      if @parsed_body.key?('error') && @parsed_body['error'].is_a?(Hash)
        nested_error = @parsed_body['error']
        error_fields.each do |field|
          if nested_error.key?(field)
            @found_messages << nested_error[field]
          end
        end
      end
    rescue JSON::ParserError
      # If not JSON, search the raw text
      @found_messages = [@body]
    end

    return @found_messages.any? if expected_message.nil?

    # Check if any found message matches the expected message
    @found_messages.any? do |msg|
      case expected_message
      when Regexp
        expected_message.match?(msg.to_s)
      else
        msg.to_s.include?(expected_message.to_s)
      end
    end
  end

  failure_message do |_actual|
    if expected_message.nil?
      'expected response to contain an error message, but none was found'
    else
      "expected error message to include '#{expected_message}', but found messages: #{@found_messages.inspect}"
    end
  end

  failure_message_when_negated do |_actual|
    if expected_message.nil?
      "expected response not to contain error messages, but found: #{@found_messages.inspect}"
    else
      "expected error message not to include '#{expected_message}', but it did"
    end
  end
end

RSpec::Matchers.define :be_rate_limited do
  match do |actual|
    return false unless actual.respond_to?(:status)

    @status = actual.status
    @status == 429
  end

  failure_message do |_actual|
    "expected HTTP status to be 429 (Too Many Requests), but got #{@status}"
  end

  failure_message_when_negated do |_actual|
    'expected HTTP status not to be 429 (Too Many Requests), but it was'
  end
end

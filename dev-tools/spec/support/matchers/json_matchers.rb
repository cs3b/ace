# frozen_string_literal: true

# Custom RSpec matchers for JSON-related assertions
RSpec::Matchers.define :be_valid_json do
  match do |actual|
    return false unless actual.is_a?(String)

    begin
      JSON.parse(actual)
      true
    rescue JSON::ParserError
      false
    end
  end

  failure_message do |actual|
    if actual.is_a?(String)
      "expected \"#{actual}\" to be valid JSON, but it failed to parse"
    else
      "expected a String, got #{actual.class}"
    end
  end

  failure_message_when_negated do |actual|
    "expected \"#{actual}\" not to be valid JSON, but it parsed successfully"
  end
end

RSpec::Matchers.define :have_json_structure do |expected_structure|
  match do |actual|
    @actual_parsed = if actual.is_a?(String)
      begin
        JSON.parse(actual)
      rescue JSON::ParserError
        return false
      end
    else
      actual
    end

    structure_matches?(@actual_parsed, expected_structure)
  end

  failure_message do |_actual|
    "expected JSON structure to match #{expected_structure.inspect}, but got #{@actual_parsed.inspect}"
  end

  failure_message_when_negated do |_actual|
    "expected JSON structure not to match #{expected_structure.inspect}, but it did"
  end

  private

  def structure_matches?(actual, expected)
    case expected
    when Hash
      return false unless actual.is_a?(Hash)
      expected.all? do |key, value|
        actual.key?(key.to_s) && structure_matches?(actual[key.to_s], value)
      end
    when Array
      return false unless actual.is_a?(Array)
      return true if expected.empty?
      # For arrays, we check if the first element matches the expected structure
      structure_matches?(actual.first, expected.first)
    when Symbol
      # Symbol represents a type check
      case expected
      when :string
        actual.is_a?(String)
      when :integer
        actual.is_a?(Integer)
      when :float
        actual.is_a?(Float)
      when :number
        actual.is_a?(Numeric)
      when :boolean
        actual == true || actual == false
      when :array
        actual.is_a?(Array)
      when :hash
        actual.is_a?(Hash)
      when :null
        actual.nil?
      else
        false
      end
    else
      actual == expected
    end
  end
end

RSpec::Matchers.define :contain_sensitive_data do |*keys|
  match do |actual|
    @sensitive_keys = keys.flatten.map(&:to_s)
    @found_keys = []

    json_data = if actual.is_a?(String)
      begin
        JSON.parse(actual)
      rescue JSON::ParserError
        # If it's not valid JSON, check the string directly for patterns
        return string_contains_sensitive_patterns?(actual)
      end
    else
      actual
    end

    find_sensitive_keys(json_data)
    @found_keys.any?
  end

  failure_message do |_actual|
    "expected to find sensitive keys #{@sensitive_keys.inspect}, but only found #{@found_keys.inspect}"
  end

  failure_message_when_negated do |_actual|
    "expected not to find sensitive keys #{@sensitive_keys.inspect}, but found #{@found_keys.inspect}"
  end

  private

  def find_sensitive_keys(data, path = [])
    case data
    when Hash
      data.each do |key, value|
        current_path = path + [key.to_s]
        if @sensitive_keys.include?(key.to_s.downcase)
          @found_keys << current_path.join(".")
        end
        find_sensitive_keys(value, current_path) if value.is_a?(Hash) || value.is_a?(Array)
      end
    when Array
      data.each_with_index do |item, index|
        find_sensitive_keys(item, path + [index]) if item.is_a?(Hash) || item.is_a?(Array)
      end
    end
  end

  def string_contains_sensitive_patterns?(str)
    @sensitive_keys.any? do |key|
      # Check for key-value patterns in string format
      pattern = /#{Regexp.escape(key)}\s*[:=]\s*["']?[^"'\s,}]+/i
      if str.match?(pattern)
        @found_keys << key
        true
      else
        false
      end
    end
  end
end

RSpec::Matchers.define :be_sanitized_json do |sensitive_keys = nil|
  match do |actual|
    @sensitive_keys = sensitive_keys || ["api_key", "password", "token", "secret"]
    @redact_value = "[REDACTED]"

    json_data = if actual.is_a?(String)
      begin
        JSON.parse(actual)
      rescue JSON::ParserError
        # For string content, check if sensitive patterns are redacted
        return string_is_sanitized?(actual)
      end
    else
      actual
    end

    json_is_sanitized?(json_data)
  end

  failure_message do |_actual|
    "expected JSON to be sanitized (sensitive keys replaced with #{@redact_value}), but found unsanitized data"
  end

  failure_message_when_negated do |_actual|
    "expected JSON not to be sanitized, but all sensitive data was redacted"
  end

  private

  def json_is_sanitized?(data)
    case data
    when Hash
      data.all? do |key, value|
        if @sensitive_keys.include?(key.to_s.downcase)
          value == @redact_value
        else
          case value
          when Hash, Array
            json_is_sanitized?(value)
          else
            true
          end
        end
      end
    when Array
      data.all? { |item| json_is_sanitized?(item) }
    else
      true
    end
  end

  def string_is_sanitized?(str)
    @sensitive_keys.all? do |key|
      # Check that any key-value patterns contain the redacted value
      pattern = /#{Regexp.escape(key)}\s*[:=]\s*["']?([^"'\s,}]+)/i
      matches = str.scan(pattern)
      matches.empty? || matches.all? { |match| match.first == @redact_value }
    end
  end
end

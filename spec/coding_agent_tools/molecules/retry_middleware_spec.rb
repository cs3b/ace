# frozen_string_literal: true

require "spec_helper"

RSpec.describe CodingAgentTools::Molecules::RetryMiddleware do
  let(:notifications) { CodingAgentTools::Notifications.notifications }
  let(:events) { [] }

  before do
    # Create an instance to register events first
    CodingAgentTools::Molecules::RetryMiddleware.new

    # Subscribe to all retry middleware events for testing
    notifications.subscribe("retry_middleware.attempt.coding_agent_tools") { |event| events << event }
    notifications.subscribe("retry_middleware.success.coding_agent_tools") { |event| events << event }
    notifications.subscribe("retry_middleware.retry.coding_agent_tools") { |event| events << event }
    notifications.subscribe("retry_middleware.failure.coding_agent_tools") { |event| events << event }

    # Mock sleep to prevent actual delays in tests
    allow_any_instance_of(CodingAgentTools::Molecules::RetryMiddleware).to receive(:sleep)
  end

  after do
    events.clear
  end

  describe "#initialize" do
    it "uses default configuration" do
      middleware = described_class.new
      expect(middleware.instance_variable_get(:@max_attempts)).to eq(3)
      expect(middleware.instance_variable_get(:@base_delay)).to eq(1.0)
      expect(middleware.instance_variable_get(:@max_delay)).to eq(60.0)
      expect(middleware.instance_variable_get(:@jitter)).to be true
    end

    it "accepts custom configuration" do
      config = {
        max_attempts: 5,
        base_delay: 2.0,
        max_delay: 120.0,
        jitter: false
      }
      middleware = described_class.new(config)
      expect(middleware.instance_variable_get(:@max_attempts)).to eq(5)
      expect(middleware.instance_variable_get(:@base_delay)).to eq(2.0)
      expect(middleware.instance_variable_get(:@max_delay)).to eq(120.0)
      expect(middleware.instance_variable_get(:@jitter)).to be false
    end
  end

  describe "#execute" do
    let(:middleware) { described_class.new(max_attempts: 3, base_delay: 0.1, jitter: false) }

    context "when operation succeeds immediately" do
      it "returns the result without retries" do
        result = middleware.execute { "success" }
        expect(result).to eq("success")
        expect(events).to have_attributes(size: 1)
        expect(events.first.id).to eq("retry_middleware.attempt.coding_agent_tools")
      end
    end

    context "when operation succeeds after retries" do
      it "retries and returns the result" do
        attempt_count = 0
        result = middleware.execute do
          attempt_count += 1
          if attempt_count < 3
            raise Faraday::TimeoutError, "Timeout"
          end
          "success after retries"
        end

        expect(result).to eq("success after retries")
        expect(attempt_count).to eq(3)

        # Should have attempt, retry, retry, success events
        expect(events).to have_attributes(size: 4)
        expect(events[0].id).to eq("retry_middleware.attempt.coding_agent_tools")
        expect(events[1].id).to eq("retry_middleware.retry.coding_agent_tools")
        expect(events[2].id).to eq("retry_middleware.retry.coding_agent_tools")
        expect(events[3].id).to eq("retry_middleware.success.coding_agent_tools")
      end
    end

    context "when operation fails permanently" do
      it "raises the final error after max attempts" do
        attempt_count = 0
        expect do
          middleware.execute do
            attempt_count += 1
            raise Faraday::TimeoutError, "Persistent timeout"
          end
        end.to raise_error(Faraday::TimeoutError, "Persistent timeout")

        expect(attempt_count).to eq(3)

        # Should have attempt, retry, retry, failure events
        expect(events).to have_attributes(size: 4)
        expect(events[0].id).to eq("retry_middleware.attempt.coding_agent_tools")
        expect(events[1].id).to eq("retry_middleware.retry.coding_agent_tools")
        expect(events[2].id).to eq("retry_middleware.retry.coding_agent_tools")
        expect(events[3].id).to eq("retry_middleware.failure.coding_agent_tools")
      end
    end

    context "with non-retryable errors" do
      it "does not retry for non-retryable errors" do
        attempt_count = 0
        expect do
          middleware.execute do
            attempt_count += 1
            raise ArgumentError, "Invalid argument"
          end
        end.to raise_error(ArgumentError, "Invalid argument")

        expect(attempt_count).to eq(1)

        # Should only have attempt and failure events
        expect(events).to have_attributes(size: 2)
        expect(events[0].id).to eq("retry_middleware.attempt.coding_agent_tools")
        expect(events[1].id).to eq("retry_middleware.failure.coding_agent_tools")
      end
    end

    context "with retryable status codes" do
      let(:response_429) { double("response", status: 429) }
      let(:response_503) { double("response", status: 503) }
      let(:response_404) { double("response", status: 404) }

      it "retries on HTTP 429 responses" do
        attempt_count = 0
        result = middleware.execute do
          attempt_count += 1
          if attempt_count < 3
            response_429
          else
            double("response", status: 200)
          end
        end

        expect(attempt_count).to eq(3)
        expect(result.status).to eq(200)
      end

      it "retries on HTTP 5xx responses" do
        attempt_count = 0
        result = middleware.execute do
          attempt_count += 1
          if attempt_count < 2
            response_503
          else
            double("response", status: 200)
          end
        end

        expect(attempt_count).to eq(2)
        expect(result.status).to eq(200)
      end

      it "does not retry on non-retryable status codes" do
        attempt_count = 0
        result = middleware.execute do
          attempt_count += 1
          response_404
        end

        expect(attempt_count).to eq(1)
        expect(result.status).to eq(404)
      end
    end

    context "with custom operation name" do
      it "includes operation name in log events" do
        middleware.execute(operation_name: "API call") { "success" }

        expect(events.first.payload[:operation]).to eq("API call")
        expect(events.first.payload[:message]).to include("API call")
      end
    end
  end

  describe "delay calculation" do
    let(:middleware) { described_class.new(base_delay: 1.0, max_delay: 60.0, jitter: false) }

    it "calculates exponential back-off correctly" do
      # Access private method for testing
      delay1 = middleware.send(:calculate_delay, 1)
      delay2 = middleware.send(:calculate_delay, 2)
      delay3 = middleware.send(:calculate_delay, 3)

      expect(delay1).to eq(1.0)  # 1 * 2^0
      expect(delay2).to eq(2.0)  # 1 * 2^1
      expect(delay3).to eq(4.0)  # 1 * 2^2
    end

    it "respects maximum delay" do
      delay = middleware.send(:calculate_delay, 10)
      expect(delay).to eq(60.0)
    end

    context "with jitter enabled" do
      let(:middleware) { described_class.new(base_delay: 1.0, jitter: true) }

      it "applies jitter to delay calculation" do
        allow(middleware).to receive(:rand).and_return(0.5)
        delay = middleware.send(:calculate_delay, 1)

        # With rand = 0.5, jitter_factor = 0.75 + 0.5 * 0.5 = 1.0
        expect(delay).to eq(1.0)
      end

      it "produces different delays with jitter" do
        delays = 10.times.map { middleware.send(:calculate_delay, 1) }
        expect(delays.uniq.size).to be > 1
      end
    end
  end

  describe "retryable error detection" do
    let(:middleware) { described_class.new }

    it "identifies retryable exceptions" do
      timeout_error = Faraday::TimeoutError.new("timeout")
      connection_error = Faraday::ConnectionFailed.new("connection failed")
      ssl_error = Faraday::SSLError.new("ssl error")

      expect(middleware.send(:should_retry?, timeout_error, 1)).to be true
      expect(middleware.send(:should_retry?, connection_error, 1)).to be true
      expect(middleware.send(:should_retry?, ssl_error, 1)).to be true
    end

    it "identifies non-retryable exceptions" do
      argument_error = ArgumentError.new("invalid argument")
      standard_error = StandardError.new("generic error")

      expect(middleware.send(:should_retry?, argument_error, 1)).to be false
      expect(middleware.send(:should_retry?, standard_error, 1)).to be false
    end

    it "respects max attempts limit" do
      timeout_error = Faraday::TimeoutError.new("timeout")

      expect(middleware.send(:should_retry?, timeout_error, 1)).to be true
      expect(middleware.send(:should_retry?, timeout_error, 2)).to be true
      expect(middleware.send(:should_retry?, timeout_error, 3)).to be false
    end
  end

  describe "retryable response detection" do
    let(:middleware) { described_class.new }

    it "identifies retryable status codes" do
      response_429 = double("response", status: 429)
      response_500 = double("response", status: 500)
      response_503 = double("response", status: 503)

      expect(middleware.send(:retryable_response?, response_429)).to be true
      expect(middleware.send(:retryable_response?, response_500)).to be true
      expect(middleware.send(:retryable_response?, response_503)).to be true
    end

    it "identifies non-retryable status codes" do
      response_200 = double("response", status: 200)
      response_404 = double("response", status: 404)
      response_401 = double("response", status: 401)

      expect(middleware.send(:retryable_response?, response_200)).to be false
      expect(middleware.send(:retryable_response?, response_404)).to be false
      expect(middleware.send(:retryable_response?, response_401)).to be false
    end

    it "handles objects without status method" do
      non_response = "not a response"

      expect(middleware.send(:retryable_response?, non_response)).to be false
    end
  end

  describe "custom retry configuration" do
    it "accepts custom retryable status codes" do
      middleware = described_class.new(retryable_status_codes: [418, 429])

      response_418 = double("response", status: 418)
      response_500 = double("response", status: 500)

      expect(middleware.send(:retryable_response?, response_418)).to be true
      expect(middleware.send(:retryable_response?, response_500)).to be false
    end

    it "accepts custom retryable exceptions" do
      custom_error = Class.new(StandardError)
      middleware = described_class.new(retryable_exceptions: [custom_error])

      error = custom_error.new("custom error")
      timeout_error = Faraday::TimeoutError.new("timeout")

      expect(middleware.send(:should_retry?, error, 1)).to be true
      expect(middleware.send(:should_retry?, timeout_error, 1)).to be false
    end
  end

  describe CodingAgentTools::Molecules::RetryMiddleware::RetryableError do
    let(:retryable_error_class) { CodingAgentTools::Molecules::RetryMiddleware::RetryableError }

    it "stores response object" do
      response = double("response", status: 429)
      error = retryable_error_class.new("Retryable error", response)

      expect(error.message).to eq("Retryable error")
      expect(error.response).to eq(response)
    end

    it "works without response object" do
      error = retryable_error_class.new("Retryable error")

      expect(error.message).to eq("Retryable error")
      expect(error.response).to be_nil
    end
  end
end

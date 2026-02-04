# frozen_string_literal: true

module Ace
  module E2eRunner
    module Models
      class TestResult
        attr_reader :test_id, :status, :summary, :test_cases, :error_type, :error_message,
                    :duration, :package, :path, :provider, :model, :raw_response

        def initialize(test_id:, status:, summary: nil, test_cases: nil, error_type: nil,
                       error_message: nil, duration: nil, package: nil, path: nil,
                       provider: nil, model: nil, raw_response: nil)
          @test_id = test_id
          @status = status
          @summary = summary
          @test_cases = test_cases
          @error_type = error_type
          @error_message = error_message
          @duration = duration
          @package = package
          @path = path
          @provider = provider
          @model = model
          @raw_response = raw_response
        end

        def success?
          status == "pass"
        end

        def failure?
          status == "fail" || status == "error" || status == "partial"
        end
      end
    end
  end
end

# frozen_string_literal: true

module Ace
  module Demo
    module Models
      class VerificationResult
        attr_reader :status, :commands_found, :commands_missing, :details, :classification, :summary, :retryable
        attr_accessor :report_path

        def initialize(success:, status:, commands_found:, commands_missing:, details: nil,
          classification: nil, summary: nil, retryable: false, report_path: nil)
          @success = success
          @status = status
          @commands_found = commands_found
          @commands_missing = commands_missing
          @details = details
          @classification = classification
          @summary = summary
          @retryable = retryable
          @report_path = report_path
        end

        def success?
          @success
        end

        def retryable?
          @retryable
        end
      end
    end
  end
end

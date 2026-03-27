# frozen_string_literal: true

module Ace
  module Demo
    module Models
      class VerificationResult
        attr_reader :status, :commands_found, :commands_missing, :details

        def initialize(success:, status:, commands_found:, commands_missing:, details: nil)
          @success = success
          @status = status
          @commands_found = commands_found
          @commands_missing = commands_missing
          @details = details
        end

        def success?
          @success
        end
      end
    end
  end
end

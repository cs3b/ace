# frozen_string_literal: true

module CodingAgentTools
  class Error < StandardError; end

  # Further specific error classes can be defined here, inheriting from CodingAgentTools::Error.
  # Example:
  #   class AuthenticationError < Error; end
  #   class FileOperationError < Error; end
end

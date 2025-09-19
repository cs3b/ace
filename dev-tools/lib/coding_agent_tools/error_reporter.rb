# frozen_string_literal: true

module CodingAgentTools
  # ErrorReporter provides a centralized way to report errors in executables
  # or other parts of the application.
  module ErrorReporter
    # Reports an error, optionally including a backtrace if debug mode is enabled.
    #
    # @param exception [Exception] The exception object to report.
    # @param debug [Boolean] Whether to include the backtrace. Defaults to false.
    # @param logger [#puts] The logger object to use for output. Defaults to $stderr.
    #   The logger must respond to the `puts` method.
    def self.call(exception, debug: false, logger: $stderr)
      logger.puts "ERROR: #{exception.message}"

      return unless debug && exception.backtrace

      logger.puts "Backtrace:"
      exception.backtrace.each do |line|
        logger.puts "  #{line}"
      end
    end
  end
end

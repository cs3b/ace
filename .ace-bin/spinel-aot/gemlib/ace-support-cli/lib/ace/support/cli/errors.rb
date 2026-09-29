# frozen_string_literal: true

module Ace
  module Support
    module Cli
      class ParseError < StandardError; end
      class CommandNotFoundError < StandardError; end

      class HelpRendered < StandardError
        attr_reader :output, :status

        def initialize(output, status: 0)
          @output = output
          @status = status
          super("Help rendered")
        end
      end
    end
  end
end

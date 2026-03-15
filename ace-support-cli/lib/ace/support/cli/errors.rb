# frozen_string_literal: true

module Ace
  module Support
    module Cli
      class ParseError < StandardError; end
      class CommandNotFoundError < StandardError; end
    end
  end
end

# frozen_string_literal: true

require "ace/lab"

module Ace
  module Lab
    module Auth
      class Error < ::Ace::Lab::Error; end
      class Refusal < Error; end
      class ExecutionCleanupError < Error; end
    end
  end
end

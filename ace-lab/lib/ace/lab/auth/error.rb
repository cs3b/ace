# frozen_string_literal: true

require "ace/lab"

module Ace
  module Lab
    module Auth
      class Error < ::Ace::Lab::Error; end
      class UncontainedSessionError < Error; end
    end
  end
end

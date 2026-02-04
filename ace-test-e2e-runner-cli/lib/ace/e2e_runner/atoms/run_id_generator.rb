# frozen_string_literal: true

require "ace/support/timestamp"

module Ace
  module E2eRunner
    module Atoms
      class RunIdGenerator
        def generate(time: Time.now.utc)
          Ace::Support::Timestamp.encode(time)
        end
      end
    end
  end
end

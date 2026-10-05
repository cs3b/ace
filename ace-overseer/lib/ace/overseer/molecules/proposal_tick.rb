# frozen_string_literal: true

require "open3"
require "json"

module Ace
  module Overseer
    module Molecules
      # The living overseer invokes the deterministic policy evaluator.
      # No timers, effect retries or executor live in this process.
      class ProposalTick
        def initialize(runner: Open3, binary: "/usr/local/bin/ace-hitl", config: ENV["ACE_HITL_HERMES_CONFIG"])
          @runner, @binary, @config = runner, binary, config
        end

        def call
          return [] if @config.to_s.empty?
          out, _err, status = @runner.capture3({"ACE_HITL_HERMES_CONFIG" => @config},
            @binary, "proposal", "resolve-due")
          raise Error, "Proposal resolution unavailable; deadlines deferred" unless status.success?
          JSON.parse(out)
        rescue JSON::ParserError, SystemCallError
          raise Error, "Proposal resolution unavailable; deadlines deferred"
        end
      end
    end
  end
end

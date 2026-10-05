# frozen_string_literal: true

require "open3"
require "json"

module Ace
  module Overseer
    module Molecules
      # The living overseer invokes the deterministic policy evaluator.
      # No timers, effect retries or executor live in this process.
      class ProposalTick
        def initialize(runner: Open3, binary: "/usr/local/bin/ace-hitl", socket: ENV["ACE_HITL_SOCKET"], project: ENV["ACE_HITL_PROJECT"])
          @runner, @binary, @socket, @project = runner, binary, socket, project
        end

        def call
          return [] if @socket.to_s.empty? || @project.to_s.empty?
          out, _err, status = @runner.capture3({"ACE_HITL_SOCKET" => @socket},
            @binary, "proposal", "resolve-due", "--project", @project)
          raise Error, "Proposal resolution unavailable; deadlines deferred" unless status.success?
          JSON.parse(out)
        rescue JSON::ParserError, SystemCallError
          raise Error, "Proposal resolution unavailable; deadlines deferred"
        end
      end
    end
  end
end

# frozen_string_literal: true

require "json"
require "ace/herdr/molecules/bounded_process"

module Ace
  module Overseer
    module Molecules
      # One bounded policy wake. These process-local active markers coalesce
      # callers; they never retain proposal outcomes or grant permission.
      class ProposalTick
        DEADLINE = 5
        LIMIT = 65_536
        @mutex = Mutex.new
        @active = {}

        def self.quiescent?
          return false if @mutex.owned?
          @mutex.synchronize { @active.empty? }
        end

        def self.acquire(key)
          @mutex.synchronize do
            return false if @active.key?(key)
            @active[key] = true
          end
        end

        def self.release(key)
          @mutex.synchronize { @active.delete(key) }
        end

        def initialize(runner: Ace::Herdr::Molecules::BoundedProcess, binary: "/usr/local/bin/ace-hitl", socket: ENV["ACE_HITL_SOCKET"], project: ENV["ACE_HITL_PROJECT"])
          @runner, @binary, @socket, @project = runner, binary, socket, project
        end

        def call
          return [] if @socket.to_s.empty? || @project.to_s.empty?
          key = [@binary, @socket, @project].map { |value| value.to_s.dup.freeze }.freeze
          return [] unless self.class.acquire(key)
          acquired = true
          result = @runner.call([{"ACE_HITL_SOCKET" => @socket}, @binary, "proposal", "resolve-due", "--project", @project],
            timeout_s: DEADLINE, output_limit: LIMIT, stderr_limit: LIMIT, cleanup_group: true)
          raise Error, "Proposal resolution unavailable; deadlines deferred" unless result.status&.success? && !result.oversized
          value = JSON.parse(result.stdout)
          raise Error, "Proposal resolution malformed; deadlines deferred" unless value.is_a?(Array) && value.all? { |item| item.is_a?(Hash) }
          value
        rescue JSON::ParserError, SystemCallError, Timeout::Error, Ace::Herdr::Molecules::BoundedProcess::PostLaunchError
          raise Error, "Proposal resolution unavailable; deadlines deferred"
        ensure
          self.class.release(key) if acquired
        end
      end
    end
  end
end

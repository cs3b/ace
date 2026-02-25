# frozen_string_literal: true

require "ace/llm"
require "open3"
require "set"

module Ace
  module Assign
    module Molecules
      # Launches a forked assignment-driving session via CLI LLM providers.
      class ForkSessionLauncher
        DEFAULT_PROVIDER = "claude:sonnet".freeze
        DEFAULT_TIMEOUT = 1800

        def initialize(config: nil, query_interface: Ace::LLM::QueryInterface)
          @config = config || Ace::Assign.config
          @query_interface = query_interface
        end

        # Launch forked subtree execution synchronously.
        #
        # @param assignment_id [String] Assignment identifier
        # @param fork_root [String] Subtree root phase number
        # @param provider [String, nil] Optional provider override
        # @param cli_args [String, nil] Optional provider CLI args
        # @param timeout [Integer, nil] Optional timeout override (seconds)
        # @return [Hash] QueryInterface response
        def launch(assignment_id:, fork_root:, provider: nil, cli_args: nil, timeout: nil)
          resolved_provider = provider || config.dig("execution", "provider") || DEFAULT_PROVIDER
          resolved_timeout = timeout || config.dig("execution", "timeout") || DEFAULT_TIMEOUT
          merged_cli_args = merge_cli_args(required_cli_args_for(resolved_provider), cli_args)
          pid_tracker = start_pid_tracker

          with_env(
            "ACE_ASSIGN_ID" => assignment_id,
            "ACE_ASSIGN_FORK_ROOT" => fork_root
          ) do
            response = query_interface.query(
              resolved_provider,
              "/ace-assign-drive",
              system: nil,
              cli_args: merged_cli_args,
              timeout: resolved_timeout,
              fallback: false
            )
            tracked_pids = stop_pid_tracker(pid_tracker)

            response.merge(
              fork_pid_info: {
                launch_pid: Process.pid,
                tracked_pids: tracked_pids
              }
            )
          end
        rescue Ace::LLM::Error => e
          raise Error, "Fork session execution failed via #{resolved_provider}: #{e.message}"
        ensure
          stop_pid_tracker(pid_tracker) if pid_tracker
        end

        private

        attr_reader :config, :query_interface

        def required_cli_args_for(provider_model)
          provider = provider_model.to_s.split(":").first
          config.dig("providers", "cli_args", provider)
        end

        def merge_cli_args(required, user_provided)
          parts = [required, user_provided].compact.map(&:to_s).map(&:strip).reject(&:empty?)
          return nil if parts.empty?

          parts.join(" ")
        end

        def with_env(vars)
          original = {}
          vars.each do |key, value|
            original[key] = ENV[key]
            ENV[key] = value.to_s
          end
          yield
        ensure
          original.each do |key, value|
            if value.nil?
              ENV.delete(key)
            else
              ENV[key] = value
            end
          end
        end

        def start_pid_tracker
          tracked = Set.new
          running = true
          root_pid = Process.pid
          worker = Thread.new do
            while running
              snapshot = process_snapshot
              descendants = descendants_of(root_pid, snapshot)
              descendants.each { |pid| tracked.add(pid) }
              sleep(0.2)
            end
          rescue StandardError
            # Best effort telemetry: ignore tracker failures.
          end

          { tracked: tracked, worker: worker, running: -> { running }, stop: -> { running = false } }
        end

        def stop_pid_tracker(tracker)
          return [] unless tracker

          tracker[:stop].call
          tracker[:worker].join(1)
          tracker[:tracked].to_a.sort
        rescue StandardError
          []
        end

        def process_snapshot
          stdout, status = Open3.capture2("ps -eo pid=,ppid=")
          return {} unless status.success?

          children_by_parent = Hash.new { |h, k| h[k] = [] }
          stdout.each_line do |line|
            pid_s, ppid_s = line.strip.split(/\s+/, 2)
            next unless pid_s && ppid_s

            pid = pid_s.to_i
            ppid = ppid_s.to_i
            next if pid <= 0 || ppid < 0

            children_by_parent[ppid] << pid
          end
          children_by_parent
        rescue StandardError
          {}
        end

        def descendants_of(root_pid, children_by_parent)
          discovered = []
          stack = Array(children_by_parent[root_pid])

          until stack.empty?
            pid = stack.pop
            next if discovered.include?(pid)

            discovered << pid
            stack.concat(Array(children_by_parent[pid]))
          end

          discovered
        end
      end
    end
  end
end

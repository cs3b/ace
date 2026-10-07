# frozen_string_literal: true

require "json"
require_relative "../../molecules/proposal_tick"

module Ace
  module Overseer
    module CLI
      module Commands
        class Status < Ace::Support::Cli::Command
          include Ace::Support::Cli::Base

          desc "Show status of active task worktrees"

          option :format, default: "table", desc: "Output format (table, json)"
          option :quiet, aliases: ["-q"], type: :boolean, default: false, desc: "Suppress non-essential output"
          option :debug, aliases: ["-d"], type: :boolean, default: false, desc: "Show debug output"
          option :watch, aliases: ["-w"], type: :boolean, default: false, desc: "Auto-refresh dashboard"
          option :runtime, desc: "Runtime (auto, tmux, herdr)"
          option :project, desc: "Read protected canonical status for this project"
          option :agent, desc: "Exact visible protected agent ID (requires --project)"

          def initialize(collector: nil, config: nil, protected_status: nil, proposal_tick: nil)
            super()
            @collector = collector || Organisms::StatusCollector.new
            @config = config
            @protected_status = protected_status || Organisms::ProtectedStatus.new
            @proposal_tick = proposal_tick || Molecules::ProposalTick.new
          end

          def call(format:, runtime: nil, project: nil, agent: nil, **options)
            raise Ace::Support::Cli::Error, "--agent requires --project" if agent && project.to_s.empty?
            selected_runtime = runtime || (@config || Ace::Overseer.config)["runtime"] || "auto"
            unless project.to_s.empty?
              unless %w[auto tmux herdr].include?(selected_runtime)
                raise Ace::Support::Cli::Error, "unsupported runtime for protected inventory"
              end
              if options[:watch]
                raise Ace::Support::Cli::Error, "Protected status is a bounded snapshot; omit --watch"
              end
              value = @protected_status.collect(project: project, agent: agent)
              unless options[:quiet]
                warn @proposal_error if @proposal_error
                value = value.merge("proposal_resolution" => {"status" => "deferred", "error" => @proposal_error}) if @proposal_error
                puts(format == "json" ? JSON.pretty_generate(value) : protected_table(value))
              end
              return
            end
            raise Ace::Support::Cli::Error, "unsupported local runtime: #{selected_runtime}" unless %w[auto tmux].include?(selected_runtime)
            tick_proposals

            Atoms::RepoGuard.ensure_repo!
            return if options[:quiet]

            if options[:watch] && format != "json"
              run_watch_loop(format, options)
            else
              run_once(format)
            end
          rescue Interrupt
            nil
          rescue => e
            raise Ace::Support::Cli::Error.new(e.message)
          end

          private

          def protected_table(value)
            lines = ["#{value.fetch('project_id')}: #{value.fetch('visible_capacity')}/#{value.fetch('provisioned_capacity')} visible mappings (#{value.fetch('visibility')})"]
            value.fetch("agents").each do |agent|
              if agent.fetch("status") != "ok"
                lines << "#{agent.fetch('agent_id')}\tunavailable"
                next
              end
              agent.fetch("inventory").fetch("items").each do |row|
                lines << [agent.fetch("agent_id"), row.fetch("assignment_id"), row.fetch("attempt_id") || "registration",
                  row.fetch("canonical_state") || "registered", row.fetch("reservation_release_event_id") ? "released" : "retained"].join("\t")
              end
            end
            lines.join("\n")
          end

          def tick_proposals
            @proposal_tick.call
            @proposal_error = nil
          rescue StandardError => e
            @proposal_error = "Proposal resolution deferred (#{e.class}); retrying on next wake"
          end

          def run_once(format)
            snapshot = @collector.collect

            if format == "json"
              value = @collector.to_h(snapshot)
              value = value.merge(proposal_resolution: {status: "deferred", error: @proposal_error}) if @proposal_error
              puts JSON.pretty_generate(value)
              return
            end

            warn @proposal_error if @proposal_error
            puts @collector.to_table(snapshot)
          end

          def run_watch_loop(format, options)
            watch_config = load_watch_config
            refresh_interval = watch_config["refresh_interval"] || 15
            git_refresh_interval = watch_config["git_refresh_interval"] || 300

            snapshot = @collector.collect
            last_full_collect = Time.now
            print_watch_screen(snapshot, git_refresh_interval, last_full_collect)

            loop do
              sleep_interruptible(refresh_interval)
              tick_proposals

              elapsed = Time.now - last_full_collect
              if elapsed >= git_refresh_interval
                snapshot = @collector.collect
                last_full_collect = Time.now
              else
                snapshot = @collector.collect_quick(snapshot)
              end

              print_watch_screen(snapshot, git_refresh_interval, last_full_collect)
            end
          end

          def print_watch_screen(snapshot, git_refresh_interval, last_full_collect)
            remaining = [(git_refresh_interval - (Time.now - last_full_collect)).round, 0].max
            print "\e[H\e[2J"
            warn @proposal_error if @proposal_error
            puts @collector.to_table(snapshot)
            puts
            puts Atoms::StatusFormatter.format_watch_footer(remaining)
          end

          def sleep_interruptible(seconds)
            seconds.times { sleep 1 }
          end

          def load_watch_config
            config = @config || Ace::Overseer.config
            config.dig("watch") || {}
          end
        end
      end
    end
  end
end

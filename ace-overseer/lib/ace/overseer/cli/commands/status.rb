# frozen_string_literal: true

require "json"

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
          option :runtime, default: "tmux", desc: "Runtime (tmux, lab)"
          option :project, desc: "Filter Lab status by project"

          def initialize(collector: nil, config: nil, lab_client: nil)
            super()
            @collector = collector || Organisms::StatusCollector.new
            @config = config
            @lab_client = lab_client || Molecules::LabClient.new
          end

          def call(format:, runtime: "tmux", project: nil, **options)
            if runtime == "lab"
              if options[:watch]
                raise Ace::Support::Cli::Error, "Lab watch runs in the project Herdr status pane; omit --watch"
              end
              arguments = ["work", "status"]
              arguments.concat(["--project", project]) unless project.to_s.empty?
              arguments << "--json" if format == "json"
              output = @lab_client.call(*arguments, json: false)
              puts output unless options[:quiet]
              return
            end
            raise Ace::Support::Cli::Error, "unsupported runtime: #{runtime}" unless runtime == "tmux"

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

          def run_once(format)
            snapshot = @collector.collect

            if format == "json"
              puts JSON.pretty_generate(@collector.to_h(snapshot))
              return
            end

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

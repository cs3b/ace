# frozen_string_literal: true

require "dry/cli"

module Ace
  module Scheduler
    module CLI
      module Commands
        class Status < Dry::CLI::Command
          include Ace::Core::CLI::DryCli::Base

          desc "Show scheduler status and recent history"

          option :config, type: :string, aliases: %w[-c], desc: "Config file path"

          def call(**options)
            config = Molecules::ConfigLoader.new.load(options[:config])
            state = Molecules::StateManager.new(state_dir: config[:state_dir])
            calculator = Atoms::NextRunCalculator.new

            tasks = config[:tasks] || {}
            puts "## Next Scheduled Runs"
            puts "| Task | Next Run | In |"
            puts "|------|----------|----|"

            tasks.each do |name, task|
              next_run = calculator.calculate(task[:cron])
              delta = calculator.time_until(next_run)
              puts "| #{name} | #{format_time(next_run)} | #{delta} |"
            end

            history = state.recent_history(limit: 10)
            if history.any?
              puts "\n## Recent History"
              puts "| Time | Task | Status | Duration |"
              puts "|------|------|--------|----------|"
              history.each do |entry|
                puts "| #{entry["time"]} | #{entry["task"]} | #{entry["status"]} | #{format_duration(entry["duration"])} |"
              end
            end
          end

          private

          def format_time(time)
            time ? time.strftime("%Y-%m-%d %H:%M") : "-"
          end

          def format_duration(duration)
            return "-" unless duration
            "#{duration.round(2)}s"
          end
        end
      end
    end
  end
end

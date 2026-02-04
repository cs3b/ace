# frozen_string_literal: true

require "dry/cli"

module Ace
  module Scheduler
    module CLI
      module Commands
        class List < Dry::CLI::Command
          include Ace::Core::CLI::DryCli::Base

          desc "List scheduled tasks and event triggers"

          option :config, type: :string, aliases: %w[-c], desc: "Config file path"

          def call(**options)
            config = Molecules::ConfigLoader.new.load(options[:config])
            state = Molecules::StateManager.new(state_dir: config[:state_dir]).load_state
            calculator = Atoms::NextRunCalculator.new

            tasks = config[:tasks] || {}
            events = config[:events] || {}

            puts "## Scheduled Tasks"
            puts ""
            puts "| Task | Schedule | Next Run | Last Run | Status |"
            puts "|------|----------|----------|----------|--------|"

            tasks.each do |name, task|
              next_run = calculator.calculate(task[:cron])
              last = state.dig(name.to_s, "last_run") || "-"
              status = task[:enabled] ? "Enabled" : "Disabled"
              puts "| #{name} | #{task[:cron]} | #{format_time(next_run)} | #{last} | #{status} |"
            end

            puts "" if events.any?
            puts "## Event Triggers" if events.any?
            puts "" if events.any?
            if events.any?
              puts "| Event | Trigger Count | Description |"
              puts "|-------|---------------|-------------|"
              events.each do |name, event|
                triggers = event[:triggers] || []
                desc = event[:description] || "-"
                puts "| #{name} | #{triggers.length} | #{desc} |"
              end
            end
          end

          private

          def format_time(time)
            time ? time.strftime("%Y-%m-%d %H:%M") : "-"
          end
        end
      end
    end
  end
end

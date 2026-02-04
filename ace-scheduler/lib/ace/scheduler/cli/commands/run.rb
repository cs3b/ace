# frozen_string_literal: true

require "dry/cli"

module Ace
  module Scheduler
    module CLI
      module Commands
        class Run < Dry::CLI::Command
          include Ace::Core::CLI::DryCli::Base

          desc "Run a scheduled task"

          argument :task, required: true
          option :config, type: :string, aliases: %w[-c], desc: "Config file path"

          def call(task:, **options)
            config = Molecules::ConfigLoader.new.load(options[:config])
            executor = Molecules::TaskExecutor.new(config)
            state = Molecules::StateManager.new(state_dir: config[:state_dir])

            result = executor.run(task)
            state.record_run(task, result)

            puts "Task '#{task}' completed: #{result.status}" unless options[:quiet]
            puts "Duration: #{format_duration(result.duration)}" unless options[:quiet]

            result.success? ? 0 : 1
          end

          private

          def format_duration(duration)
            "#{duration.round(2)}s"
          end
        end
      end
    end
  end
end

# frozen_string_literal: true

require "dry/cli"

module Ace
  module Scheduler
    module CLI
      module Commands
        class Emit < Dry::CLI::Command
          include Ace::Core::CLI::DryCli::Base

          desc "Emit an event and run its triggers"

          argument :event, required: true
          option :config, type: :string, aliases: %w[-c], desc: "Config file path"

          def call(event:, **options)
            config = Molecules::ConfigLoader.new.load(options[:config])
            event_config = config.dig(:events, event.to_sym)

            raise Ace::Core::CLI::Error.new("Unknown event: #{event}") unless event_config

            triggers = event_config[:triggers] || []
            puts "Emitting event: #{event}" unless options[:quiet]
            puts "Triggers: #{triggers.length}" unless options[:quiet]

            executor = Molecules::TaskExecutor.new(config)
            results = []

            triggers.each_with_index do |trigger, index|
              command = trigger[:command]
              result = executor.run_command(command, task: event)
              results << result
              status = result.success? ? "success" : "failed"
              puts "  [#{index + 1}/#{triggers.length}] #{command}: #{status} (#{format_duration(result.duration)})" unless options[:quiet]
            end

            results.all?(&:success?) ? 0 : 1
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

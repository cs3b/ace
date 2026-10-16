# frozen_string_literal: true
require_relative "cli/commands/explore"
require_relative "cli/commands/adjust"
require_relative "cli/commands/preset"
require_relative "cli/commands/run_commands"
require_relative "cli/commands/doctor"
require_relative "cli/commands/preview"
require_relative "cli/commands/inspect"
require_relative "cli/commands/validate"
module Ace
  module Design
    module CLI
      extend Ace::Support::Cli::RegistryDsl
      PROGRAM_NAME = "ace-design"
      REGISTERED_COMMANDS = [["profile adjust", "Update project design decisions"], ["profile refresh", "Refresh library defaults"], ["profile show", "Read effective profile"], ["preset list", "List design processes"], ["preset show", "Inspect a design preset"], ["explore", "Explore new directions"], ["recreate", "Faithfully reproduce a source"], ["reimagine", "New appearance, same goals"], ["revise", "Apply targeted feedback"],
        ["status", "Show worker progress"], ["resume", "Resume unfinished workers"], ["select", "Select a direction"], ["doctor", "Check local browser runtime"], ["preview", "Serve a mockup session locally"],
        ["inspect", "Inspect a URL with browser evidence"], ["validate", "Validate catalog or session"]].freeze
      def self.start(args)
        flags = %w[--input --prompt-append --variant-prompt --variant-prompt-file --decision].to_h { |f| [f, []] }
        args = Ace::Support::Cli::ArgvCoalescer.call(args, flags: flags, separator: "\x1f")
        Ace::Support::Cli::Runner.new(self).call(args: args)
      end
      def self.output(result, json: false)
        return puts(JSON.pretty_generate(result)) if json
        puts "Status: #{result['status']}" if result['status']
        puts "Session: #{result['id'] || result['session']}" if result['session']
        puts "Artifacts: #{result['session']}" if result['session']
        puts "Brief:\n#{result['brief']}" if result['brief']
        if result['resolved']
          resolved = result.fetch('resolved')
          puts "#{resolved['intent']} · #{resolved['surface']}/#{resolved['kind']} · preset #{resolved['name']}"
          puts "All-model override: #{resolved['model_override']}" if resolved['model_override']
          puts "Preparation: #{resolved['preparation_model']}"
          resolved.fetch('variants').each { |slot| puts "#{slot['id']}: #{slot['model']} · #{slot.fetch('process', 'ace')} · #{slot['prompt']}" }
          puts YAML.dump(resolved.slice('source', 'profile', 'requirements'))
        end
        result.fetch('workers', {}).each do |id, worker|
          puts "#{id}: #{worker['status']}"
          puts worker.fetch('attempts', []).last['error'] if worker.fetch('attempts', []).last&.key?('error')
        end
        puts "Report: #{result['report_dir']}" if result['report_dir']
        puts "Contexts: #{result['contexts'].join(', ')}" if result['contexts']
        puts "Next: #{result['next']}" if result['next']
      end
      def self.session_path(value)
        return value if File.directory?(value)
        return File.join(Design.config.fetch("run_root"), value) if /\A[0-9a-z]+\z/.match?(value)
        value
      end
      def self.entries(value)
        value.to_s.split("\x1f")
      end
      register "profile adjust", Commands::Adjust
      register "profile refresh", Commands::Refresh
      register "profile show", Commands::Context
      register "preset list", Commands::PresetList
      register "preset show", Commands::PresetShow
      register "explore", Commands::Explore
      register "recreate", Commands::Recreate
      register "reimagine", Commands::Reimagine
      register "revise", Commands::Revise
      register "status", Commands::Status
      register "resume", Commands::Resume
      register "select", Commands::Select
      register "doctor", Commands::Doctor
      register "preview", Commands::Preview
      register "inspect", Commands::Inspect
      register "validate", Commands::Validate
      help = Ace::Support::Cli::HelpCommand.build(program_name: PROGRAM_NAME, version: VERSION, commands: REGISTERED_COMMANDS,
        examples: ["ace-design preview .ace-local/design/SESSION", "ace-design inspect http://localhost:3000 --surface app", "ace-design validate"])
      register "help", help
      register "--help", help
      register "-h", help
      version = Ace::Support::Cli::VersionCommand.build(gem_name: "ace-design", version: VERSION)
      register "version", version
      register "--version", version
    end
  end
end

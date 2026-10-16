# frozen_string_literal: true
require "optparse"
require_relative "../../organisms/command_run_client"
module Ace
  module Lab
    module CLI
      module Commands
        class Run < Ace::Support::Cli::Command
          desc "Run one explicitly authorized project command"
          option :project, required: true, desc: "Installed project ID"
          option :as, desc: "Configured permitted executor"
          option :service, repeat: true, desc: "Replace default services with this complete set"
          argument :argv, type: :array, desc: "Literal command argv after --"

          def self.parse(args)
            separator = args.index("--")
            raise ArgumentError, "run requires -- followed by literal command argv" unless separator && separator < args.size - 1
            switches, argv = args.first(separator), args.drop(separator + 1)
            options = {executor: nil, services: nil}
            seen = {}
            parser = OptionParser.new
            %w[project as].each do |name|
              parser.on("--#{name} VALUE") do |value|
                raise ArgumentError, "duplicate --#{name}" if seen[name]
                seen[name] = true
                options[name == "as" ? :executor : :project] = value
              end
            end
            parser.on("--service VALUE") { |value| (options[:services] ||= []) << value }
            parser.parse!(switches)
            raise ArgumentError, "run requires one --project and no extra options" unless seen["project"] && switches.empty?
            options.merge(argv: argv)
          rescue OptionParser::ParseError, ArgumentError
            raise Ace::Support::Cli::Error, "usage_error: run requires unique project/executor options and literal argv after --"
          end

          def self.invoke(args)
            options = parse(args)
            project = options.delete(:project)
            client = Organisms::CommandRunClient.new(project: project)
            begin
              client.run(**options, pane: ENV["HERDR_PANE_ID"])
            rescue StandardError, SecurityError
              # Once admission may have crossed the owner boundary, even a
              # malformed stream is uncertainty, never a fresh usage refusal.
              raise Ace::Support::Cli::Error, "command_uncertain: inspect the original execution reference before new work"
            end
          rescue Ace::Lab::InvalidConfigurationError
            raise Ace::Support::Cli::Error, "invalid_command_context: installed project selection is unavailable"
          end
        end
        class RunStatus < Ace::Support::Cli::Command
          desc "Inspect an original command execution without running it"
          option :project, required: true
          option :reference, required: true
          def call(project:, reference:, **)
            puts JSON.generate(Organisms::CommandRunClient.new(project: project).status(reference))
          rescue StandardError, SecurityError
            raise Ace::Support::Cli::Error, "command_status_unavailable: preserve original execution reference"
          end
        end
      end
    end
  end
end

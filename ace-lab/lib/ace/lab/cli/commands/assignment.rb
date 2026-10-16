# frozen_string_literal: true

require_relative "../../organisms/ordinary_assignment_client"

module Ace
  module Lab
    module CLI
      module Commands
        module Assignment
          class Prepare < Ace::Support::Cli::Command
            desc "Retain reviewed task input for ordinary Assign registration"
            option :project, required: true, desc: "Installed project ID"
            option :task, required: true, desc: "Reviewed leaf task ID"
            option :pane, required: true, desc: "Actual supervisor pane for registration"
            option :output, required: true, desc: "New private directory for retained input"
            option :dependency_reports, desc: "JSON array of explicit dependency report selections"

            def call(project:, task:, pane:, output:, **options)
              reports = options[:dependency_reports] ? JSON.parse(Organisms::OrdinaryAssignmentClient.read_file(
                options.fetch(:dependency_reports), 65_536), allow_duplicate_key: false, create_additions: false, max_nesting: 16) : []
              puts JSON.generate(Organisms::OrdinaryAssignmentClient.prepare(project: project, task: task,
                pane: pane, output: output, dependency_reports: reports))
            rescue JSON::ParserError, ArgumentError, KeyError, SystemCallError, Ace::Assign::Error, Ace::Runtime::Error => error
              raise Ace::Support::Cli::Error, "ordinary preparation incomplete: #{error.message}; retain existing files"
            end
          end

          class Request < Ace::Support::Cli::Command
            desc "Send one retained operation to the installed ordinary Assign owner"
            option :project, required: true, desc: "Installed project ID"
            option :input, required: true, desc: "Retained request JSON with original mutation and part digests"
            option :output, desc: "New private directory for a canonical snapshot download"

            def call(project:, input:, **options)
              service = Organisms::OrdinaryAssignmentClient.new(project: project)
              puts JSON.generate(service.request(input: input, output: options[:output]))
            rescue ArgumentError, KeyError, SystemCallError, Ace::Assign::Error, Ace::Runtime::Error, Ace::Lab::Error => error
              raise Ace::Support::Cli::Error, "ordinary assignment unavailable: #{error.message}; retain the original request; inspect status before new work"
            end
          end
        end
      end
    end
  end
end

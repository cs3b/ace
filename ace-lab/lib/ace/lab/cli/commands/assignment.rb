# frozen_string_literal: true

require_relative "../../organisms/ordinary_assignment_client"
require "ace/assign/organisms/ordinary_driver"

module Ace
  module Lab
    module CLI
      module Commands
        module Assignment
          class Drive < Ace::Support::Cli::Command
            desc "Drive or inspect one original ordinary execution through its installed owner"
            option :project, required: true, desc: "Installed project ID; never inferred from local Assign"
            option :context, required: true, desc: "Original retained ordinary context.json"
            option :operation, required: true, desc: "status, supervisor, adopt-supervisor, bootstrap, next, start, step-start, step-finish, fail, result, adopt, replay"
            option :previous_binding_sha256, desc: "Exact canonical old supervisor binding digest for adoption"
            option :output, desc: "New private directory for accepted bootstrap context"
            option :pane, desc: "Actual native caller pane (defaults to HERDR_PANE)"
            option :generation, type: :integer, desc: "Exact canonical generation observed before mutation"
            option :step, desc: "Exact queue step within the retained scope"
            option :report, desc: "Executed step's bounded UTF-8 report file"
            option :message, desc: "Failure reason"
            option :receipt, desc: "Attributable execution receipt JSON"
            option :artifact, type: :array, desc: "Artifact files in receipt order"
            option :request, desc: "Original mutation request to replay after reconciliation"

            def call(project:, context:, operation:, **options)
              transport = Organisms::OrdinaryAssignmentClient.new(project: project)
              driver = Ace::Assign::Organisms::OrdinaryDriver.new(path: context, project: project, transport: transport)
              pane = options[:pane] || ENV["HERDR_PANE"]
              result = case operation
              when "status" then driver.status
              when "supervisor" then driver.supervisor
              when "adopt-supervisor"
                driver.adopt_supervisor(pane: pane, generation: options.fetch(:generation),
                  previous_binding_sha256: options.fetch(:previous_binding_sha256))
              when "bootstrap" then driver.bootstrap(output: options.fetch(:output))
              when "next" then driver.queue
              when "start" then driver.start(pane: pane)
              when "step-start", "step-finish", "fail"
                driver.progress(operation: {"step-start" => "queue_start", "step-finish" => "queue_finish", "fail" => "queue_fail"}.fetch(operation),
                  pane: pane, generation: options.fetch(:generation), step: options[:step],
                  report: operation == "step-finish" ? options.fetch(:report) : nil,
                  message: operation == "fail" ? options.fetch(:message) : nil)
              when "result"
                driver.submit(pane: pane, generation: options.fetch(:generation), receipt: options.fetch(:receipt), artifacts: options[:artifact] || [])
              when "adopt" then driver.adopt(pane: pane)
              when "replay" then driver.replay(input: options.fetch(:request))
              else raise ArgumentError, "unknown ordinary driver operation"
              end
              puts JSON.generate(result)
            rescue ArgumentError, KeyError, SystemCallError, Ace::Assign::Error, Ace::Runtime::Error, Ace::Lab::Error => error
              raise Ace::Support::Cli::Error, "ordinary execution unavailable: #{error.message}; inspect the original context with --operation status"
            end
          end

          class Prepare < Ace::Support::Cli::Command
            desc "Retain reviewed task input for ordinary Assign registration"
            option :project, required: true, desc: "Installed project ID"
            option :task, required: true, desc: "Reviewed leaf task ID"
            option :pane, required: true, desc: "Actual supervisor pane for registration"
            option :output, required: true, desc: "New private directory for retained input"
            option :dependency_reports, desc: "JSON array of explicit dependency report selections"

            def call(project:, task:, pane:, output:, **options)
              reports = options[:dependency_reports] ? JSON.parse(Ace::Assign::Authority::RetainedInput.read_file(
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

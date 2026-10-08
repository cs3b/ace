# frozen_string_literal: true

require "ace/support/cli"
require "ace/core"
require_relative "../assign"

# Models
require_relative "models/assignment"
require_relative "models/step"
require_relative "models/queue_state"
require_relative "models/assignment_info"
require_relative "models/attempt_binding"
require_relative "models/attempt"
require_relative "models/execution_receipt"
require_relative "models/evidence_event"

# Atoms
require_relative "atoms/step_numbering"
require_relative "atoms/number_generator"
require_relative "atoms/preset_expander"
require_relative "atoms/preset_loader"
require_relative "atoms/preset_step_resolver"
require_relative "atoms/step_file_parser"
require_relative "atoms/step_sorter"
require_relative "atoms/catalog_loader"
require_relative "atoms/composition_rules"
require_relative "atoms/assign_frontmatter_parser"
require_relative "atoms/tree_formatter"
require_relative "atoms/attempt_state_machine"
require_relative "atoms/evidence_digest"
require_relative "atoms/assignment_scope"

# Molecules
require_relative "molecules/lifecycle_exclusion"
require_relative "molecules/assignment_manager"
require_relative "molecules/attempt_store"
require_relative "molecules/assignment_discoverer"
require_relative "molecules/queue_scanner"
require_relative "molecules/step_writer"
require_relative "molecules/step_renumberer"
require_relative "molecules/skill_assign_source_resolver"
require_relative "molecules/fork_session_launcher"
require_relative "molecules/runtime_control_surface_runner"
require_relative "molecules/preset_inferrer"
require_relative "molecules/evidence_calculator"
require_relative "molecules/evidence_journal"
require_relative "molecules/canonical_evidence"
require_relative "molecules/execution_identity_resolver"
require_relative "molecules/receipt_verifier"
require_relative "molecules/attempt_reconciler"

# Organisms
require_relative "organisms/assignment_executor"
require_relative "organisms/attempt_coordinator"

# Commands
require_relative "cli/commands/delivery"
require_relative "cli/commands/assignment_target"
require_relative "cli/commands/create"
require_relative "cli/commands/status"
require_relative "cli/commands/resume"
require_relative "cli/commands/inbox_reconcile"
require_relative "cli/commands/inbox_bind"
require_relative "cli/commands/inbox_observe"
require_relative "cli/commands/inbox_settle"
require_relative "cli/commands/submit_candidate"
require_relative "cli/commands/submit_result"
require_relative "cli/commands/campaign_record_round"
require_relative "cli/commands/campaign_export_result"
require_relative "cli/commands/step"
require_relative "cli/commands/start"
require_relative "cli/commands/finish"
require_relative "cli/commands/fail"
require_relative "cli/commands/add"
require_relative "cli/commands/retry_cmd"
require_relative "cli/commands/list"
require_relative "cli/commands/select"
require_relative "cli/commands/fork_run"
require_relative "cli/commands/fork_session"
require_relative "cli/commands/authority/serve"
require_relative "cli/commands/authority/launch"
require_relative "cli/commands/authority/status"
require_relative "cli/commands/authority/terminate"
require_relative "cli/commands/authority/worker"
require_relative "cli/commands/authority/task_context"
require_relative "cli/commands/authority/task_context_principal"
require_relative "cli/commands/authority/task_context_selection"
require_relative "cli/commands/authority/inbox_context_principal"
require_relative "cli/commands/authority/inbox_context_selection"
require_relative "cli/commands/attempt/base"
require_relative "cli/commands/attempt/start"
require_relative "cli/commands/attempt/status"
require_relative "cli/commands/attempt/finish"
require_relative "cli/commands/attempt/reconcile"
require_relative "cli/commands/attempt/evidence"

module Ace
  module Assign
    # ace-support-cli based CLI registry for ace-assign
    module CLI
      extend Ace::Support::Cli::RegistryDsl

      PROGRAM_NAME = "ace-assign"

      # Application commands with descriptions (for help output)
      REGISTERED_COMMANDS = [
        ["create", "Create assignment from preset or YAML"],
        ["authority serve", "Serve the installed protected assignment owner"],
        ["authority launch", "Launch one mapped native gated worker"],
        ["authority status", "Inspect protected launch ownership"],
        ["authority terminate", "Terminate the original native gated child"],
        ["authority worker", "Consume original authenticated prepared work"],
        ["authority task-context", "Read captured original task context through the fixed entry"],
        ["authority task-context-principal", "Classify the actual caller through retained protected owners"],
        ["authority task-context-selection", "Read the authenticated original context entry selection"],
        ["authority inbox-context-principal", "Classify the actual caller through every retained protected owner"],
        ["authority inbox-context-selection", "Read the fixed installed inbox context selection"],
        ["delivery", "Execute or reconcile attempt-bound forge delivery"],
        ["submit-candidate", "Submit original protected worker candidate bytes"],
        ["submit-result", "Submit original protected worker receipt and artifact bytes"],
        ["campaign-export-result", "Download the original parent campaign's verified accepted result"],
        ["campaign-record-round", "Consume canonical settled children into the original campaign store"],
        ["status", "Show assignment status"],
        ["step", "Show step instructions"],
        ["start", "Start next workable step"],
        ["finish", "Complete current step with report"],
        ["fail", "Mark step as failed"],
        ["add", "Add step to assignment"],
        ["retry", "Retry failed step"],
        ["list", "List all assignments"],
        ["select", "Select active assignment"],
        ["fork-run", "Run subtree in forked process"],
        ["attempt start", "Start a scoped attempt for an assignment step"],
        ["attempt status", "Show attempt status for an assignment"],
        ["attempt evidence", "Read accepted current-head check evidence"],
        ["attempt finish", "Finish a protected canonical result or an ordinary local receipt"],
        ["attempt reconcile", "Recover an exact protected attempt or reconcile an ordinary attempt"],
        ["inbox-bind", "Bind an original protected Inbox registration"],
        ["inbox-observe", "Import an owner-verified native observation"],
        ["inbox-settle", "Verify and sign canonical native observation evidence"]
      ].freeze

      HELP_EXAMPLES = [
        "ace-assign create --preset review     # Start review assignment",
        "ace-assign status                     # Compact queue progress",
        "ace-assign step                       # Current or next step instructions",
        "ace-assign start                      # Start next workable step",
        "ace-assign finish --message done.md    # Complete active step",
        "cat report.md | ace-assign finish     # Complete step via stdin",
        "ace-assign fork-run 010.01            # Run subtree in subprocess",
        "ace-assign attempt start --assignment ID --step 010 --project ID",
        "ace-assign attempt finish --attempt ID --receipt receipt.json",
        "ace-assign resume --assignment ID --dry-run"
      ].freeze

      # Captured command exit code from last run
      @captured_exit_code = nil

      # Start the CLI
      #
      # @param args [Array<String>] Command-line arguments
      # @return [Integer] Exit code (0 for success, non-zero for failure)
      def self.start(args)
        @captured_exit_code = nil
        Ace::Support::Cli::Runner.new(self).call(args: args)
        @captured_exit_code || 0
      end

      # Wrap a command to capture its exit code
      #
      # @param command_class [Class] The command class to wrap
      # @return [Class] Wrapped command class
      def self.wrap_command(command_class)
        wrapped = Class.new(Ace::Support::Cli::Command) do
          define_method(:call) do |**kwargs|
            result = command_class.new.call(**kwargs)
            Ace::Assign::CLI.instance_variable_set(:@captured_exit_code, result) if result.is_a?(Integer)
            result
          end
        end
        # Copy metadata from original class
        command_class.instance_variables.each do |ivar|
          wrapped.instance_variable_set(ivar, command_class.instance_variable_get(ivar))
        end
        wrapped
      end

      # Register commands (wrapped to capture exit codes)
      register "authority serve", wrap_command(Commands::Authority::Serve)
register "authority launch", wrap_command(Commands::Authority::Launch)
register "authority status", wrap_command(Commands::Authority::Status)
register "authority terminate", wrap_command(Commands::Authority::Terminate)
register "authority worker", wrap_command(Commands::Authority::Worker)
register "authority task-context", wrap_command(Commands::Authority::TaskContext)
register "authority task-context-principal", wrap_command(Commands::Authority::TaskContextPrincipal)
register "authority task-context-selection", wrap_command(Commands::Authority::TaskContextSelection)
register "authority inbox-context-principal", wrap_command(Commands::Authority::InboxContextPrincipal)
register "authority inbox-context-selection", wrap_command(Commands::Authority::InboxContextSelection)
      register "create", wrap_command(Commands::Create)
      register "delivery", wrap_command(Commands::Delivery)
      register "status", wrap_command(Commands::Status)
      register "step", wrap_command(Commands::Step)
      register "start", wrap_command(Commands::Start)
      register "finish", wrap_command(Commands::Finish)
      register "fail", wrap_command(Commands::Fail)
      register "add", wrap_command(Commands::Add)
      register "retry", wrap_command(Commands::RetryCmd)
      register "list", wrap_command(Commands::List)
      register "select", wrap_command(Commands::Select)
      register "fork-run", wrap_command(Commands::ForkRun)
      register "fork-session", wrap_command(Commands::ForkSession)
      register "attempt start", wrap_command(Commands::Attempt::Start)
      register "attempt status", wrap_command(Commands::Attempt::Status)
      register "attempt evidence", wrap_command(Commands::Attempt::Evidence)
      register "attempt finish", wrap_command(Commands::Attempt::Finish)
      register "attempt reconcile", wrap_command(Commands::Attempt::Reconcile)
      register "resume", wrap_command(Commands::Resume)
      register "inbox-reconcile", wrap_command(Commands::InboxReconcile)
      register "inbox-bind", wrap_command(Commands::InboxBind)
      register "inbox-observe", wrap_command(Commands::InboxObserve)
      register "inbox-settle", wrap_command(Commands::InboxSettle)
      register "submit-candidate", wrap_command(Commands::SubmitCandidate)
      register "submit-result", wrap_command(Commands::SubmitResult)
      register "campaign-export-result", wrap_command(Commands::CampaignExportResult)
      register "campaign-record-round", wrap_command(Commands::CampaignRecordRound)

      # Register version command
      version_cmd = Ace::Support::Cli::VersionCommand.build(
        gem_name: "ace-assign",
        version: Ace::Assign::VERSION
      )
      register "version", version_cmd
      register "--version", version_cmd

      # Register help command
      help_cmd = Ace::Support::Cli::HelpCommand.build(
        program_name: PROGRAM_NAME,
        version: Ace::Assign::VERSION,
        commands: REGISTERED_COMMANDS,
        examples: HELP_EXAMPLES
      )
      register "help", help_cmd
      register "--help", help_cmd
      register "-h", help_cmd
    end
  end
end

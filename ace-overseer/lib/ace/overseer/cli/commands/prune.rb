# frozen_string_literal: true

module Ace
  module Overseer
    module CLI
      module Commands
        class Prune < Ace::Support::Cli::Command
          include Ace::Support::Cli::Base

          desc "Clean up completed task worktrees with executed preservation and no-writer proofs"

          argument :targets, required: false, type: :array, desc: "Task refs or folder names to prune"

          option :assignment, aliases: ["-a"], type: :string, desc: "Prune a specific assignment by ID"
          option :force, aliases: ["-f"], type: :boolean, default: false,
            desc: "Skip the confirmation prompt for already-safe candidates; never bypasses safety blocks"
          option :yes, aliases: ["-y"], type: :boolean, default: false, desc: "Skip confirmation"
          option :dry_run, type: :boolean, default: false, desc: "Show candidates only (no cleanup side effects)"
          option :quiet, aliases: ["-q"], type: :boolean, default: false,
            desc: "Suppress progress output; failures still print and signal via exit code"
          option :debug, aliases: ["-d"], type: :boolean, default: false, desc: "Show debug output"
          option :runtime, default: "tmux", desc: "Runtime (tmux, lab)"
          option :preservation, type: :string,
            desc: "YAML manifest (version 1) declaring verified cross-repository destinations"

          def initialize(orchestrator: nil, input: $stdin, output: $stdout, lab_client: nil,
            lab_safety_checker: nil, preservation_checker: nil)
            super()
            @orchestrator = orchestrator || Organisms::PruneOrchestrator.new
            @input = input
            @output = output
            @lab_client = lab_client || Molecules::LabClient.new
            @lab_safety_checker = lab_safety_checker || Molecules::LabPruneSafetyChecker.new
            @preservation_checker = preservation_checker || Molecules::GitPreservationChecker.new
          end

          def call(**options)
            runtime = options.fetch(:runtime, "tmux")
            if runtime == "lab"
              prune_lab(**options)
              return
            end
            raise Ace::Support::Cli::Error, "unsupported runtime: #{runtime}" unless runtime == "tmux"

            Atoms::RepoGuard.ensure_repo!

            targets = Array(options[:targets] || [])
            progress = options[:quiet] ? nil : ->(msg) { puts msg }
            result = @orchestrator.call(
              dry_run: options[:dry_run],
              yes: options[:yes],
              force: options[:force],
              targets: targets,
              assignment_id: options[:assignment],
              preservation_manifest: options[:preservation],
              input: @input,
              output: @output,
              on_progress: progress
            )

            if options[:assignment]
              print_assignment_result(result)
              return if options[:dry_run] || result[:aborted]

              raise Ace::Support::Cli::Error, "Assignment #{options[:assignment]} is blocked: " \
                "#{result[:assignment_candidate].reasons.join(", ")}" if result[:blocked]
              unless result[:pruned_assignments].any?
                raise Ace::Support::Cli::Error, "Failed to remove assignment #{options[:assignment]}"
              end

              return
            end

            if result[:dry_run]
              print_dry_run(result)
              return
            end

            puts "Prune aborted." if result[:aborted]
            return if result[:aborted]

            print_apply(result)

            blocked_count = Array(result[:unsafe]).length + Array(result[:blocked]).length +
              Array(result[:failed]).length
            return if blocked_count.zero?

            raise Ace::Support::Cli::Error,
              "#{blocked_count} candidate(s) blocked or failed; nothing unsafe was removed"
          rescue Ace::Overseer::Error => e
            raise Ace::Support::Cli::Error, e.message
          end

          private

          def prune_lab(**options)
            raise Ace::Support::Cli::Error, "--assignment is not supported with Lab runtime; provide exact Work IDs" if options[:assignment]
            raise Ace::Support::Cli::Error, "--force is not supported with Lab runtime" if options[:force]
            raise Ace::Support::Cli::Error, "--preservation is not supported with Lab runtime" if options[:preservation]

            works = Array(options[:targets]).map(&:to_s)
            raise Ace::Support::Cli::Error, "provide at least one exact Lab Work ID to prune" if works.empty?

            classifications = if atomic_destroy_supported?
              works.to_h do |work|
                [work, @lab_safety_checker.check(
                  lab_client: @lab_client,
                  work_id: work,
                  preservation_proof: lab_preservation_proof(work)
                )]
              end
            else
              # The raw Lab surface cannot make the no-writer check and the
              # destruction atomic; claiming a probe was safe would be a
              # lie, so the whole path is unsupported and preserved.
              unsupported = Molecules::LabPruneSafetyChecker::Classification.new(
                safe?: false,
                reason: "lab runtime cannot make the no-writer check and destruction atomic; " \
                  "preserve the Work instead"
              )
              works.to_h { |work| [work, unsupported] }
            end

            if options[:dry_run]
              print_lab_dry_run(classifications)
              return
            end

            raise Ace::Support::Cli::Error, "Lab prune requires --yes after reviewing --dry-run" unless options[:yes]

            blocked = []
            destroyed = []
            works.each do |work|
              classification = classifications[work]
              unless classification.safe?
                blocked << [work, classification.reason]
                next
              end

              # Guarded delegation: re-read the authoritative state
              # immediately before destroy; a changed state aborts.
              recheck = @lab_safety_checker.check(
                lab_client: @lab_client,
                work_id: work,
                preservation_proof: lab_preservation_proof(work)
              )
              unless recheck.safe?
                blocked << [work, "state changed before destroy: #{recheck.reason}"]
                next
              end

              result = @lab_client.call("work", "destroy", work, "--confirm", json: false)
              destroyed << work
              puts result unless options[:quiet]
            end

            blocked.each do |work, reason|
              puts "Blocked: lab work #{work}: #{reason}"
            end
            puts "#{destroyed.length} lab work(s) destroyed." unless options[:quiet]
            return if blocked.empty?

            raise Ace::Support::Cli::Error, "#{blocked.length} lab work(s) blocked; nothing unsafe was destroyed"
          end

          # Delegation is only honest when the Lab surface itself can make
          # the state check and the destruction atomic. The raw CLI adapter
          # cannot, so it reports unsupported; adapters with an atomic
          # guarded destroy opt in.
          def atomic_destroy_supported?
            @lab_client.respond_to?(:supports_atomic_destroy?) && @lab_client.supports_atomic_destroy?
          end

          # Preservation evidence for a Lab Work comes from the Work's own
          # documented surviving identity (repo/head/branch). A surface that
          # does not document it cannot prove preservation.
          def lab_preservation_proof(work)
            entry = @lab_client.work_entry(work)
            return Models::PreservationProof.blocked("lab work #{work} not found in authoritative status") if entry.nil?

            repo = entry["repo"].to_s
            head = entry["head"].to_s
            branch = entry["branch"].to_s
            if repo.empty? || head.empty? || branch.empty? || !repo.start_with?("/")
              return Models::PreservationProof.blocked(
                "lab work #{work} does not document preservation data (repo/head/branch)"
              )
            end

            accepted_base = @preservation_checker.accepted_base_for(repo)
            @preservation_checker.ancestry_proof(repo: repo, head: head, accepted_base: accepted_base)
          rescue Ace::Overseer::Error => e
            Models::PreservationProof.blocked("lab preservation evidence unavailable: #{e.message}")
          end

          def print_lab_dry_run(classifications)
            puts "Lab prune classification:"
            classifications.each do |work, classification|
              if classification.safe?
                puts "  #{work}: safe (terminal, preserved, no in-flight work)"
              else
                puts "  #{work}: BLOCKED — #{classification.reason}"
              end
            end
          end

          def print_assignment_result(result)
            candidate = result[:assignment_candidate]
            if result[:dry_run]
              puts "Assignment: #{candidate.assignment_id} (#{candidate.assignment_name})"
              puts "  State: #{candidate.assignment_state}"
              puts "  Safe to prune: #{candidate.safe_to_prune? ? "yes" : "no"}"
              puts "  Reasons: #{candidate.reasons.join(", ")}" if candidate.reasons.any?
              return
            end

            if result[:aborted]
              puts "Prune aborted."
              return
            end

            if result[:blocked]
              puts "Blocked: assignment #{candidate.assignment_id}: #{candidate.reasons.join(", ")}"
              return
            end

            pruned = result[:pruned_assignments]
            if pruned.any?
              puts "Removed assignment #{candidate.assignment_id}."
            else
              puts "Failed to remove assignment #{candidate.assignment_id}."
            end
          end

          def print_dry_run(result)
            puts "Candidates for cleanup:"
            if result[:safe].empty?
              puts "  (none)"
            else
              result[:safe].each do |candidate|
                puts "  task.#{candidate.task_id} - #{candidate.worktree_path}"
              end
            end
            if result[:unsafe].any?
              puts "Blocked candidates:"
              result[:unsafe].each do |candidate|
                puts "  task.#{candidate.task_id} - #{candidate.worktree_path}"
                candidate.reasons.each { |reason| puts "    - #{reason}" }
              end
            end
            puts
            puts "#{result[:safe].length} worktree(s) can be pruned; " \
              "#{result[:unsafe].length} blocked."
          end

          def print_apply(result)
            result[:pruned].each do |candidate|
              puts "Removed worktree task.#{candidate.task_id}"
            end
            Array(result[:unsafe]).each do |candidate|
              puts "Blocked: task.#{candidate.task_id}: #{candidate.reasons.join(", ")}"
            end
            Array(result[:blocked]).each do |entry|
              puts "Blocked after recheck: task.#{entry[:candidate].task_id}: #{entry[:reasons].join(", ")}"
            end
            result[:failed].each do |entry|
              puts "Failed to remove task.#{entry[:candidate].task_id}: #{entry[:error]}"
            end
            puts "#{result[:pruned].length} worktree(s) pruned."
          end
        end
      end
    end
  end
end

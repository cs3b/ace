# frozen_string_literal: true

module Ace
  module Overseer
    module Molecules
      # Fail-closed safety classification for assignment cache pruning.
      #
      # The cache directory of an assignment is disposable only when its
      # durable evidence survives outside the deletion target and every
      # attempt is provably terminal:
      #
      # - the queue label must read completed (never proof by itself),
      # - recorded attempts must be terminal — active or uncertain attempts
      #   block, and unreadable attempt state blocks,
      # - managed assignments must carry their durable evidence in
      #   refs/ace/execution; a missing or unreadable evidence ref blocks,
      #   and journal-derived active/uncertain attempts block even when the
      #   local records were lost.
      #
      # The journal checkout and the evidence ref are never deletion targets:
      # cleanup removes only the assignment cache directory.
      class AssignmentPruneSafetyChecker
        def initialize(assignment_discoverer_factory: nil, assignment_manager_factory: nil,
          journal_factory: nil)
          @assignment_discoverer_factory = assignment_discoverer_factory || -> { Ace::Assign::Molecules::AssignmentDiscoverer.new }
          @assignment_manager_factory = assignment_manager_factory || -> { Ace::Assign::Molecules::AssignmentManager.new }
          @journal_factory = journal_factory || -> {
            Ace::Assign::Molecules::EvidenceJournal.new(
              repo_root: Ace::Support::Fs::Molecules::ProjectRootFinder.find_or_current
            )
          }
        end

        def check(assignment_id:)
          discoverer = @assignment_discoverer_factory.call
          all = discoverer.find_all(include_completed: true)
          info = all.find { |ai| ai.assignment.id == assignment_id }

          unless info
            return Models::AssignmentPruneCandidate.new(
              assignment_id: assignment_id,
              assignment_name: "",
              assignment_state: "not_found",
              location_path: "",
              attempts_terminal: false,
              reasons: ["assignment not found"]
            )
          end

          state = info.queue_state.assignment_state.to_s
          reasons = []
          reasons << "assignment still #{state}" unless state == "completed"

          attempts_terminal, attempt_reasons = attempts_evidence(info.assignment, assignment_id)
          reasons.concat(attempt_reasons)

          Models::AssignmentPruneCandidate.new(
            assignment_id: assignment_id,
            assignment_name: info.assignment.name,
            assignment_state: state,
            location_path: info.assignment.cache_dir,
            attempts_terminal: attempts_terminal,
            reasons: reasons
          )
        end

        private

        def attempts_evidence(assignment, assignment_id)
          managed = begin
            assignment.managed?
          rescue => e
            return [false, ["assignment lifecycle state unreadable: #{e.message}"]]
          end

          reasons = []
          local_terminal, local_reasons = local_attempts(assignment_id)
          reasons.concat(local_reasons)

          if managed
            journal_terminal, journal_reasons = journal_evidence(assignment_id)
            reasons.concat(journal_reasons)
            [local_terminal && journal_terminal, reasons]
          else
            [local_terminal, reasons]
          end
        end

        def local_attempts(assignment_id)
          attempts = @assignment_manager_factory.call.attempts(assignment_id)
          terminal = true
          reasons = []
          attempts.each do |attempt|
            next unless attempt.active? || attempt.uncertain?

            terminal = false
            reasons << "attempt #{attempt.attempt_id} is #{attempt.state}"
          end
          [terminal, reasons]
        rescue => e
          [false, ["attempt state unreadable: #{e.message}"]]
        end

        # The journal is the durable evidence outside the deletion target:
        # managed cleanup requires it to exist and to agree that no attempt
        # is active or uncertain.
        def journal_evidence(assignment_id)
          journal = @journal_factory.call
          ref_value = journal.ref_value
          if ref_value.nil?
            return [false, ["no durable evidence ref for managed assignment #{assignment_id}"]]
          end

          terminal = true
          reasons = []
          journal.derived_attempts(assignment_id).each do |attempt|
            next unless attempt.active? || attempt.uncertain?

            terminal = false
            reasons << "journaled attempt #{attempt.attempt_id} is #{attempt.state}"
          end
          [terminal, reasons]
        rescue => e
          [false, ["durable evidence unreadable: #{e.message}"]]
        end
      end
    end
  end
end

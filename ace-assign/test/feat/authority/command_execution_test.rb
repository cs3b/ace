# frozen_string_literal: true

require_relative "../../test_helper"
require "ace/assign/authority/command_execution"

module Ace
  module Assign
    class CommandExecutionTest < AceAssignTestCase
      # Authorization is the Lab policy's responsibility. This fixture exercises
      # the real journal and recovery; it is not a distinct-user launch proof.
      class Admission
        attr_accessor :enabled, :definition, :canonical_launcher
        def initialize
          @enabled = true
          @definition = {"argv" => ["/usr/bin/true"], "services" => [], "executor" => {"uid" => 1002}}
        end
        def command_reader!(**) = check!
        def command_request!(**) = (check!; @definition)
        def command_launcher!(peer:, **)
          check!
          raise AttemptErrors::UnauthorizedIdentity unless peer["uid"] == 0
          @canonical_launcher || peer
        end
        def command_claim!(caller:, **)
          check!
          raise AttemptErrors::UnauthorizedIdentity unless caller == {"uid" => 1000}
        end
        def command_child!(child:, **)
          check!
          raise AttemptErrors::UnauthorizedIdentity unless child["uid"] == 1002
          child
        end
        def check!
          raise AttemptErrors::UnauthorizedIdentity unless @enabled
        end
      end

      def setup
        super
        @operator = {"pid" => 11, "uid" => 1000, "started_at" => "operator-birth"}
        @launcher = {"pid" => 22, "uid" => 0, "started_at" => "launcher-birth"}
        @admission = Admission.new
      end

      def with_owner
        Dir.mktmpdir do |root|
          repo = File.join(root, "repo")
          FileUtils.mkdir_p(repo)
          git_in(repo, "init", "-b", "main")
          git_in(repo, "-c", "user.name=test", "-c", "user.email=test@example.org", "commit", "--allow-empty", "-m", "base")
          @journal = Molecules::EvidenceJournal.new(repo_root: repo, checkout_root: File.join(root, "projection"))
          restart
          yield root
        end
      end

      def restart
        @owner = Authority::CommandExecution.new(project: "ace", journal: @journal, admission: @admission)
      end

      def call(operation, extra = {}, mutation: operation, peer: nil)
        @owner.dispatch(request: {"project_id" => "ace", "operation" => operation,
          "mutation_id" => operation == "command_status" ? nil : mutation,
          "params" => {"execution_id" => "run-1"}.merge(extra)},
          peer: peer || (operation == "command_admit" ? @operator : @launcher), role: :worker,
          deadline: Process.clock_gettime(Process::CLOCK_MONOTONIC) + 10)
      end

      def admit = call("command_admit", {"selection" => {"argv" => ["/usr/bin/true"]}})
      def claim = call("command_claim", {"caller" => {"uid" => 1000}})
      def bind = call("command_bind", {"child" => {"pid" => 33, "uid" => 1002, "birth" => "child-birth"}})

      def test_command_is_canonical_without_task_or_prepared_work_and_restart_projects_exact_exit
        with_owner do |root|
          admitted = admit
          assert_equal "admitted", admitted.dig(:data, "phase")
          assert_equal [], @journal.derived_attempts("command-run-1")
          claim
          bound = bind
          refute bound.fetch(:replayed)
          result = call("command_complete", {"result" => {"exit_status" => 19, "signal" => nil}})
          assert_equal "exited", result.dig(:data, "phase")
          FileUtils.rm_rf(@journal.checkout_root)
          restart
          status = call("command_status")
          assert_equal result.fetch(:data), status.fetch(:data)
          assert_equal 19, status.dig(:data, "result", "exit_status")
          refute status.fetch(:data).key?("delivery")
        end
      end

      def test_claim_and_bind_replay_remain_replayed_after_lost_ack_and_never_become_fresh
        with_owner do
          admit
          first = claim
          restart
          assert_equal first.fetch(:data), claim.fetch(:data)
          assert claim.fetch(:replayed)
          first_bind = bind
          restart
          assert bind.fetch(:replayed)
          assert_equal first_bind.fetch(:data), bind.fetch(:data)
          assert_raises(AttemptErrors::Conflict) do
            call("command_bind", {"child" => {"pid" => 44, "uid" => 1002, "birth" => "other"}})
          end
          assert_raises(AttemptErrors::Conflict) do
            call("command_claim", {"caller" => {"uid" => 1000}}, mutation: "another-claim")
          end
        end
      end

      def test_policy_revocation_and_changed_launcher_refuse_without_new_history
        with_owner do
          admit
          claim
          before = @journal.ref_value
          @admission.enabled = false
          assert_raises(AttemptErrors::UnauthorizedIdentity) { bind }
          assert_equal before, @journal.ref_value
          @admission.enabled = true
          assert_raises(AttemptErrors::UnauthorizedIdentity) do
            call("command_bind", {"child" => {"uid" => 1002}}, peer: @launcher.merge("started_at" => "reused-pid"))
          end
          assert_equal before, @journal.ref_value
        end
      end

      def test_short_lived_helper_uses_canonical_daemon_identity_for_replay
        with_owner do
          @admission.canonical_launcher = @launcher
          admit
          first = call("command_claim", {"caller" => {"uid" => 1000}}, peer: @launcher.merge("pid" => 30))
          assert_equal @launcher, first.dig(:data, "launcher")
          replay = call("command_claim", {"caller" => {"uid" => 1000}}, peer: @launcher.merge("pid" => 31))
          assert replay.fetch(:replayed)
          assert_equal first.fetch(:data), replay.fetch(:data)
        end
      end

      def test_concurrent_claims_admit_only_one_execution_intent
        with_owner do
          admit
          replies = Queue.new
          threads = 2.times.map do |index|
            Thread.new do
              begin
                replies << call("command_claim", {"caller" => {"uid" => 1000}}, mutation: "claim-#{index}")
              rescue AttemptErrors::Conflict => error
                replies << error
              end
            end
          end
          threads.each(&:join)
          actual = 2.times.map { replies.pop }
          assert_equal 1, actual.count { |reply| reply.is_a?(Hash) && !reply.fetch(:replayed) }
          assert_equal 1, actual.count { |reply| reply.is_a?(AttemptErrors::Conflict) }
          assert_equal "claimed", call("command_status").dig(:data, "phase")
        end
      end

      def test_child_mismatch_bad_result_and_duplicate_invocation_refuse
        with_owner do
          admit
          assert_raises(AttemptErrors::Conflict) do
            call("command_admit", {"selection" => {"argv" => ["/usr/bin/false"]}})
          end
          claim
          assert_raises(AttemptErrors::UnauthorizedIdentity) do
            call("command_bind", {"child" => {"uid" => 1000}})
          end
          bind
          assert_raises(ArgumentError) do
            call("command_complete", {"result" => {"exit_status" => 0, "signal" => 9}})
          end
          result = call("command_complete", {"result" => {"exit_status" => nil, "signal" => 9}})
          assert_equal 9, result.dig(:data, "result", "signal")
        end
      end
    end
  end
end

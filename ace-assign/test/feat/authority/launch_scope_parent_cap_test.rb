# frozen_string_literal: true
require_relative "../../test_helper"
require "ace/assign/authority/launch_lifecycle"
require "ace/assign/authority/launch_driver"
require_relative "../../support/execution_scope_observation_fixtures"
require_relative "../../support/prepared_registration_fixture"

module Ace
  module Assign
    class LaunchScopeParentCapTest < AceAssignTestCase
      class Kernel
        Handle = Struct.new(:closed) { def close; self.closed = true; end }
        def capture(_pid); {"pid" => 81, "uid" => 13002}; end
        def live!(_identity); true; end
        def same?(left, right); left == right; end
        def pin(_identity); Handle.new(false); end
      end
      def self.class_temp_dir
        @class_temp_dir ||= Dir.mktmpdir("ace-launch-parent-", Etc.getpwuid(Process.uid).dir)
      end
      Reply = Struct.new(:data, :replayed)

      def test_production_parent_observer_driver_abort_release_and_next_reservation
        with_temp_cache do |cache|
          repo = File.join(cache, "repo")
          FileUtils.mkdir_p(repo)
          _out, err, status = Open3.capture3("git", "init", "-b", "main", repo)
          assert status.success?, err
          _out, err, status = Open3.capture3("git", "-C", repo, "-c", "user.name=test", "-c", "user.email=test@localhost", "commit", "--allow-empty", "-m", "fixture")
          assert status.success?, err
          journal = Molecules::EvidenceJournal.new(repo_root: repo, checkout_root: File.join(cache, "checkout"))
          kernel = Kernel.new
          map = {"project_id" => "project", "authority_id" => "authority", "worker_uid" => 13001, "launcher_uid" => 13002,
            "worker_actor" => "worker", "execution_scope" => {"slot_id" => "slot", "slice_unit" => "ace-slot.slice",
              "service_unit" => "ace-slot.service", "runtime_directory" => "/run/slot/native", "network_namespace_path" => "/run/netns/slot"}}
          deployment = Object.new
          deployment.define_singleton_method(:artifact_reference) { {"sha256" => "d" * 64} }
          deployment.define_singleton_method(:mapping) { |_id| map }
          deployment.define_singleton_method(:verify!) { |*_args, **_options| true }
          deployment.define_singleton_method(:authority) { |_id| {"uid" => 13000, "state_root" => File.join(cache, "state")} }
          deployment.define_singleton_method(:project) { |_id| {"supervisor_uids" => [13003], "inbox_contexts" => {}, "candidate_root" => cache, "assignment_root" => File.join(cache, "assignments")} }
          manager = ExecutionScopeObservationFixtures::Manager.new
          files = ExecutionScopeObservationFixtures::Files.new
          cgroups = ExecutionScopeObservationFixtures::Cgroups.new
          observer = Authority::ExecutionScopeObservation.new(mapping_id: "mapping", deployment: deployment, kernel: kernel,
            manager: manager, files: files, cgroups: cgroups,
            boot_evidence: ExecutionScopeObservationFixtures::BootEvidence.new)
          owner = Authority::LaunchLifecycle.new(deployment: deployment, kernel: kernel, journals: {"project" => journal},
            scope_observer_factory: ->(_id) { observer })
          client = Object.new
          client.define_singleton_method(:call) do |operation, params, mutation_id: nil, upload_parts: nil, purpose: nil|
            input = upload_parts && Struct.new(:parts) { def count = parts.size; def bytes(index: 0) = parts.fetch(index) }.new(upload_parts)
            params = params.merge("transfer" => Authority::TransferCodec.new.descriptor(upload_parts, purpose: purpose)) if upload_parts
            result = owner.dispatch(request: {"operation" => operation, "mutation_id" => mutation_id,
              "params" => params.merge("mapping_id" => "mapping")}, peer: kernel.capture(Process.pid), role: :launcher, transfer: input)
            Reply.new(result.fetch(:data), result.fetch(:replayed))
          end
          driver = Authority::LaunchDriver.new(mapping_id: "mapping", deployment: deployment, kernel: kernel, client: client)
          bytes = JSON.generate("session_id" => "assignment", "name" => "test", "created_at" => "2026-10-05T00:00:00Z",
            "source_config" => "job.yaml", "task_id" => "09j", "project_id" => "project")
          prepared = PreparedRegistrationFixture.build(root: cache, definition: JSON.parse(bytes), scope: "010")
          bytes = prepared.definition_bytes
          result = driver.launch(assignment_id: "assignment", definition_bytes: bytes, prepared_bundle: prepared.bundle, scope: "010", base_head: "a" * 40, mutation_id: "first")
          assert_equal "failed", result["phase"], result.inspect
          assert_equal 1, manager.starts
          assert_equal 0, manager.service_starts
          events = journal.read_events("assignment")
          assert_equal 1, events.count { |event| event["type"] == "scope_bound" }
          assert_equal 1, events.count { |event| event["type"] == "scope_closed_no_writers" }
          assert_equal 1, events.count { |event| event.dig("payload", "operation") == "scope_reservation_release" }
          refute events.any? { |event| %w[scope_native_bound scope_child_bound process_start].include?(event["type"]) }
          owner.close
          owner = Authority::LaunchLifecycle.new(deployment: deployment, kernel: kernel, journals: {"project" => journal},
            scope_observer_factory: ->(_id) { observer })
          before_replay = journal.ref_value
          replay = driver.launch(assignment_id: "assignment", definition_bytes: bytes, prepared_bundle: prepared.bundle, scope: "010", base_head: "a" * 40, mutation_id: "first")
          assert_equal "reserved", replay["phase"]
          assert_equal "inspect_retained_reservation_no_creation_permission", replay["required_action"]
          assert_equal before_replay, journal.ref_value
          assert_equal 1, manager.starts
          assert_equal 0, manager.slice_stops
          second = driver.launch(assignment_id: "assignment", definition_bytes: bytes, prepared_bundle: prepared.bundle, scope: "010", base_head: "a" * 40, mutation_id: "second")
          assert_equal "failed", second["phase"], second.inspect
          assert_equal 2, manager.starts
          assert_equal 1, manager.slice_stops
          refute_equal result["attempt_id"], second["attempt_id"]
          assert_equal 0, manager.service_starts
        ensure
          owner&.close
        end
      end
    end
  end
end

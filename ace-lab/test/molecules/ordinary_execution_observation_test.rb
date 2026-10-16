# frozen_string_literal: true

require_relative "../test_helper"
require_relative "../support/ordinary_owner_fixture"
require "ace/lab/molecules/ordinary_owner_admission"

module Ace
  module Lab
    module Molecules
      class OrdinaryExecutionObservationTest < Minitest::Test
        include OrdinaryOwnerFixture

        def test_start_uses_matching_native_worker_pid_cwd_and_its_actual_head
          with_worker do |admission, head|
            result = admission.execution!(peer: @peer, pane: "w1:p1", head: head)
            assert_equal 50, result.fetch(:identity).process_pid
            assert_equal @worker, result.fetch(:checkout).fetch("cwd")
            assert_equal head, result.fetch(:checkout).fetch("head")
            assert_equal [50, 50], @requested_pids
            assert_raises(Ace::Assign::AttemptErrors::UnauthorizedIdentity) do
              admission.execution!(peer: @peer, pane: "w1:p1", head: "a" * 40)
            end
          end
        end

        def test_changed_native_process_birth_cwd_or_workspace_cannot_become_an_execution
          [:birth, :cwd, :workspace].each do |change|
            with_worker do |admission, head|
              @change = change
              assert_raises(Ace::Assign::AttemptErrors::UnauthorizedIdentity) do
                admission.execution!(peer: @peer, pane: "w1:p1", head: head)
              end
            end
          end
        end

        def test_trusted_consumer_rechecks_exact_recorded_binding_and_current_worker_checkout
          with_worker do |admission, head|
            original = admission.identity!(peer: @peer, pane: "w1:p1").runtime_binding
            observed = admission.recorded_execution!(binding: original, head: head)
            assert_equal original, observed.fetch(:runtime_binding)
            assert_equal head, observed.fetch(:checkout).fetch("head")
            assert_raises(Ace::Assign::AttemptErrors::UnauthorizedIdentity) do
              admission.recorded_execution!(binding: original, head: "f" * 40)
            end
            @change = :birth
            assert_raises(Ace::Assign::AttemptErrors::UnauthorizedIdentity) do
              admission.recorded_execution!(binding: original, head: head)
            end
          end
        end

        def test_recorded_worker_cannot_be_observed_after_becoming_a_protected_principal
          with_worker do |admission, _head|
            original = admission.identity!(peer: @peer, pane: "w1:p1").runtime_binding
            @protected_uid = @peer.fetch("uid")
            assert_raises(Ace::Assign::AttemptErrors::UnauthorizedIdentity) do
              admission.recorded_binding!(binding: original)
            end
          end
        end

        private

        def with_worker
          Dir.mktmpdir("ordinary-execution-", Etc.getpwuid(Process.uid).dir) do |root|
            @worker = File.join(root, "worker")
            FileUtils.mkdir_p(@worker)
            git(@worker, "init", "-b", "main")
            git(@worker, "-c", "user.name=test", "-c", "user.email=test@example.invalid", "commit", "--allow-empty", "-m", "worker")
            head = git(@worker, "rev-parse", "HEAD").strip
            @peer = {"pid" => 123, "uid" => 41001, "gid" => 41001, "started_at" => "caller", "host" => "lab"}
            document = ordinary_owner_document(peer: @peer)
            document["projects"]["atlas"]["worktrees"] = {"root" => root, "common_dir" => File.join(@worker, ".git")}
            config = OrdinaryOwnerConfig.new(document, project: "atlas", source: OrdinaryOwnerConfig::PATH)
            kernel = Object.new
            kernel.define_singleton_method(:live!) { |value, **_| value }
            runtime = Object.new
            @observations, @requested_pids, @change, @protected_uid = 0, [], nil, nil
            observed_binding = -> {
              @observations += 1
              {"runtime" => "herdr", "session" => @observations > 1 && @change == :workspace ? "foreign" : "w1", "pane" => "w1:p1",
                "process_identity" => @peer.except("gid").merge("pid" => 50, "started_at" => @observations > 1 && @change == :birth ? "replacement" : "worker")}
            }
            cwd = ->(pid) {
              @requested_pids << pid
              @observations > 1 && @change == :cwd ? root : @worker
            }
            runtime.define_singleton_method(:process_binding) { |**_| observed_binding.call }
            runtime.define_singleton_method(:process_cwd) { |pid| cwd.call(pid) }
            admission = OrdinaryOwnerAdmission.new(config: config, peer: kernel, runtime: runtime)
            OrdinaryOwnerConfig.stub(:load, config) do
              protection = ->(uid:) { Struct.new(:protected_participant?).new(uid == @protected_uid) }
              Ace::Assign::Authority::ProtectedAssignmentContext.stub(:load, protection) do
                Etc.stub(:getpwuid, Struct.new(:name).new("atlas-worker")) { yield admission, head }
              end
            end
          end
        end

        def git(directory, *args)
          output, error, status = Open3.capture3("/usr/bin/git", "-C", directory, *args)
          raise error unless status.success?
          output
        end
      end
    end
  end
end

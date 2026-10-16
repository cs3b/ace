# frozen_string_literal: true

require_relative "../test_helper"
require_relative "../support/ordinary_owner_fixture"
require "ace/lab/molecules/ordinary_owner_admission"

module Ace
  module Lab
    module Molecules
      class OrdinaryOwnerAdmissionTest < Minitest::Test
        include OrdinaryOwnerFixture
        def setup
          @peer = {"uid" => 41001, "gid" => 41001, "pid" => 123, "host" => "lab", "started_at" => "birth"}
          @context = Object.new
          @context.define_singleton_method(:protected_participant?) { false }
          @config = OrdinaryOwnerConfig.new(document, project: "atlas", source: OrdinaryOwnerConfig::PATH)
          @kernel = Object.new
          @kernel.define_singleton_method(:live!) { |value, **_| value }
          @runtime = Object.new
          @binding = {"runtime" => "herdr", "session" => "w1", "pane" => "w1:p1", "process_identity" => @peer.except("gid")}
        end

        def test_closed_owner_selection_is_detached_and_rejects_caller_owned_or_overlapping_state
          original = document
          selected = OrdinaryOwnerConfig.new(original, project: "atlas", source: OrdinaryOwnerConfig::PATH)
          original["projects"]["atlas"]["participants"]["41001"]["role"] = "supervisor"
          assert_equal "worker", selected.participants.fetch("41001").fetch("role")
          assert_raises(FrozenError) { selected.participants.fetch("41001")["role"] = "supervisor" }
          [->(d) { d["service"]["uid"] = 41001 },
            ->(d) { d["service"]["uid"] = 0 },
            ->(d) { d["journal"]["repository"] = "/var/lib/ace/state/journal" },
            ->(d) { d["assignment_root"] = "/var/lib/ace/state/checkout/assignments" },
            ->(d) { d["participants"]["41001"]["role"] = "root" },
            ->(d) { d["native"]["socket_identity"][2] = 41001 },
            ->(d) { d["participants"]["41001"]["argv"] = ["/bin/sh"] }].each do |change|
            modified = document
            change.call(modified.fetch("projects").fetch("atlas"))
            assert_raises(InvalidConfigurationError) { OrdinaryOwnerConfig.new(modified, project: "atlas", source: OrdinaryOwnerConfig::PATH) }
          end
        end

        def test_project_role_and_native_process_come_from_installed_and_observed_sources
          @runtime.define_singleton_method(:process_binding) do |pane:, caller_pid:|
            raise "unverified selector" unless pane == "w1:p1" && caller_pid == 123
            {"runtime" => "herdr", "session" => "w1", "pane" => pane,
              "process_identity" => {"pid" => 50, "uid" => 41001, "host" => "lab", "started_at" => "agent-birth"}}
          end
          admission = OrdinaryOwnerAdmission.new(config: @config, runtime: @runtime, peer: @kernel)
          with_selection do
            assert_equal :worker, admission.authorize!(request: {"project_id" => "atlas"}, peer: @peer)
            identity = admission.identity!(peer: @peer, pane: "w1:p1")
            assert_equal ["atlas-worker", "worker", "herdr", 50], [identity.actor, identity.role, identity.runtime, identity.process_pid]
            assert_raises(Ace::Assign::AttemptErrors::UnauthorizedIdentity) do
              admission.authorize!(request: {"project_id" => "borealis"}, peer: @peer)
            end
            assert_raises(Ace::Assign::AttemptErrors::UnauthorizedIdentity) do
              admission.authorize!(request: {"project_id" => "atlas"}, peer: @peer.merge("uid" => 42000))
            end
          end
        end

        def test_missing_foreign_workspace_or_reused_owner_never_becomes_a_start
          admission = OrdinaryOwnerAdmission.new(config: @config, runtime: @runtime, peer: @kernel)
          [nil, @binding.merge("session" => "w2"), @binding.merge("process_identity" => @peer.merge("uid" => 42000))].each do |binding|
            @runtime.define_singleton_method(:process_binding) { |**_| binding }
            with_selection do
              assert_raises(Ace::Assign::AttemptErrors::UnauthorizedIdentity) { admission.identity!(peer: @peer, pane: "w1:p1") }
            end
          end
          @runtime.define_singleton_method(:process_binding) { |**_| @binding }
          @kernel.define_singleton_method(:live!) { |_, **_| raise Ace::Assign::AttemptErrors::UnauthorizedIdentity, "pid changed" }
          with_selection do
            assert_raises(Ace::Assign::AttemptErrors::UnauthorizedIdentity) { admission.identity!(peer: @peer, pane: "w1:p1") }
          end
        end

        def test_revoked_installed_selection_and_retained_protected_principal_fail_before_native_lookup
          admission = OrdinaryOwnerAdmission.new(config: @config, runtime: @runtime, peer: @kernel)
          changed = document
          changed.fetch("projects").fetch("atlas").fetch("participants").fetch("41001")["actor"] = "replacement"
          replacement = OrdinaryOwnerConfig.new(changed, project: "atlas", source: OrdinaryOwnerConfig::PATH)
          OrdinaryOwnerConfig.stub(:load, replacement) do
            assert_raises(InvalidConfigurationError) { admission.authorize!(request: {"project_id" => "atlas"}, peer: @peer) }
          end
          @context.define_singleton_method(:protected_participant?) { true }
          with_selection do
            assert_raises(Ace::Assign::AttemptErrors::UnauthorizedIdentity) { admission.authorize!(request: {"project_id" => "atlas"}, peer: @peer) }
          end
        end

        def test_requester_configuration_cannot_select_owner_or_grants
          Dir.mktmpdir("ordinary-untrusted-") do |root|
            path = File.join(root, "owner.yml")
            File.write(path, YAML.safe_dump(document))
            assert_raises(InvalidConfigurationError) { OrdinaryOwnerConfig.load(project: "atlas", path: path) }
          end
        end

        def test_another_projects_caller_cannot_be_the_journal_owner
          modified = document
          other = Marshal.load(Marshal.dump(modified.fetch("projects").fetch("atlas")))
          other["service"]["uid"] = 42000
          other["participants"]["41000"] = other["participants"].delete("41001")
          modified["projects"]["borealis"] = other
          %w[atlas borealis].each do |project|
            assert_raises(InvalidConfigurationError) do
              OrdinaryOwnerConfig.new(modified, project: project, source: OrdinaryOwnerConfig::PATH)
            end
          end
        end

        def test_owner_becoming_protected_is_rechecked_by_running_admission
          admission = OrdinaryOwnerAdmission.new(config: @config, runtime: @runtime, peer: @kernel)
          protected = false
          OrdinaryOwnerConfig.stub(:load, @config) do
            Etc.stub(:getpwuid, Struct.new(:name).new("atlas-worker")) do
            Ace::Assign::Authority::ProtectedAssignmentContext.stub(:load, ->(uid:) {
              Struct.new(:protected_participant?).new(protected && uid == 41000)
            }) do
              assert_equal :worker, admission.authorize!(request: {"project_id" => "atlas"}, peer: @peer)
              protected = true
              assert_raises(Ace::Assign::AttemptErrors::UnauthorizedIdentity) do
                admission.authorize!(request: {"project_id" => "atlas"}, peer: @peer)
              end
            end
            end
          end
        end

        def test_revocation_during_native_probe_cannot_return_an_identity
          current = @config
          modified = document
          modified["projects"]["atlas"]["participants"]["41001"]["role"] = "reviewer"
          revoked = OrdinaryOwnerConfig.new(modified, project: "atlas", source: OrdinaryOwnerConfig::PATH)
          binding = @binding
          @runtime.define_singleton_method(:process_binding) { |**_| current = revoked; binding }
          admission = OrdinaryOwnerAdmission.new(config: @config, runtime: @runtime, peer: @kernel)
          OrdinaryOwnerConfig.stub(:load, ->(**_) { current }) do
            Etc.stub(:getpwuid, Struct.new(:name).new("atlas-worker")) do
            Ace::Assign::Authority::ProtectedAssignmentContext.stub(:load, @context) do
              assert_raises(InvalidConfigurationError) { admission.identity!(peer: @peer, pane: "w1:p1") }
            end
            end
          end
        end

        private

        def with_selection
          OrdinaryOwnerConfig.stub(:load, @config) do
            Etc.stub(:getpwuid, Struct.new(:name).new("atlas-worker")) do
            Ace::Assign::Authority::ProtectedAssignmentContext.stub(:load, ->(uid:) {
              raise "wrong classification identity" unless [41000, 41001, 42000].include?(uid)
              @context
            }) { yield }
            end
          end
        end

        def document
          ordinary_owner_document(peer: @peer)
        end
      end
    end
  end
end

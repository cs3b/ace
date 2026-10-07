# frozen_string_literal: true
require_relative "../../test_helper"
require "ace/assign/authority/launch_lifecycle"
require "ace/runtime/molecules/execution_boot_baseline"
require_relative "../../support/execution_scope_observation_fixtures"

module Ace
  module Assign
    class HistoricalBootBaselineTest < AceAssignTestCase
      class Protection
        def root_path!(_); true; end
        def verify!(_, handle, directory:)
          raise "wrong fixture type" unless directory ? handle.stat.directory? : handle.stat.file?
        end
      end

      def artifact(root, name, bytes)
        path = File.join(root, name)
        File.binwrite(path, bytes)
        {"path" => path, "sha256" => Digest::SHA256.hexdigest(bytes), "bytes" => bytes.bytesize}
      end

      def with_original
        with_temp_cache do |root|
          root = File.realpath(root)
          producer = artifact(root, "installer", "retained installer")
          binding = {"slot_id" => "slot", "boot_id" => "12345678-1234-1234-1234-123456789abc", "deployment_digest" => "a" * 64,
            "network_installation_selection" => {"installer_artifact" => producer}}
          proof = binding.slice("slot_id", "boot_id", "deployment_digest").merge("schema" => "ace.execution-boot-baseline/v1",
            "producer_artifact" => producer, "host_ipc_namespace_identity" => {"device" => 4, "inode" => 900},
            "host_devpts_identity" => ExecutionScopeObservationFixtures::DEVPTS_HOST,
            "host_ptmx_link" => "pts/ptmx", "selected_devpts" => ExecutionScopeObservationFixtures::DEVPTS_SELECTED,
            "original_host_context" => {"pid" => 1, "uid" => 0, "gid" => 0, "started_at" => "linux:#{binding.fetch('boot_id')}:1"})
          binding["boot_baseline_selection"] = artifact(root, "original.json", JSON.generate(proof))
          factory = lambda do
            reader = Ace::Runtime::Molecules::ExecutionBootBaseline.allocate
            reader.send(:initialize, artifacts: Ace::Runtime::Molecules::ProtectedArtifactSet.new(protection: Protection.new))
            reader
          end
          Ace::Runtime::Molecules::ExecutionBootBaseline.stub(:new, factory) do
            yield Authority::LaunchLifecycle.allocate, binding, root
          end
        end
      end

      def verify(owner, binding)
        owner.send(:verify_historical_boot_baseline!, binding)
      end

      def test_original_ref_authenticates_without_any_current_pointer_or_boot_discovery
        with_original do |owner, binding, root|
          assert_equal({"device" => 4, "inode" => 900}, verify(owner, binding).fetch("host_ipc_namespace_identity"))
          %w[slot_id boot_id deployment_digest].each do |field|
            wrong = binding.merge(field => field == "boot_id" ? "22345678-1234-1234-1234-123456789abc" : (field == "deployment_digest" ? "b" * 64 : "other"))
            assert_raises(AttemptErrors::EvidenceUnavailable) { verify(owner, wrong) }
          end
          wrong_installer = artifact(root, "different-installer", "different valid installer")
          assert_raises(AttemptErrors::EvidenceUnavailable) { verify(owner, binding.merge("network_installation_selection" => {"installer_artifact" => wrong_installer})) }
          assert_raises(AttemptErrors::EvidenceUnavailable) { verify(owner, binding.except("boot_baseline_selection")) }
          assert_raises(AttemptErrors::EvidenceUnavailable) { verify(owner, binding.merge("network_installation_selection" => nil)) }
        end
      end

      def test_missing_or_replaced_original_and_installer_refuse_without_substitution
        with_original do |owner, binding, root|
          original = binding.fetch("boot_baseline_selection")
          bytes = File.binread(original.fetch("path"))
          File.binwrite(original.fetch("path"), bytes + " ")
          assert_raises(AttemptErrors::EvidenceUnavailable) { verify(owner, binding) }
          File.binwrite(original.fetch("path"), bytes)
          File.unlink(original.fetch("path"))
          artifact(root, "current.json", bytes)
          assert_raises(AttemptErrors::EvidenceUnavailable) { verify(owner, binding) }
          File.binwrite(original.fetch("path"), bytes)
          File.binwrite(binding.dig("network_installation_selection", "installer_artifact", "path"), "replaced installer")
          assert_raises(AttemptErrors::EvidenceUnavailable) { verify(owner, binding) }
        end
      end
    end
  end
end

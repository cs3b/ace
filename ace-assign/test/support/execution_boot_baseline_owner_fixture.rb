# frozen_string_literal: true
require "ace/runtime/molecules/execution_boot_baseline"
require_relative "execution_scope_observation_fixtures"

module Ace
  module Assign
    module ExecutionBootBaselineOwnerFixture
      # Controlled trusted capture content; actual retained bytes, references,
      # parser, context joins and held-FD provenance are the production owners.
      def retained_boot_baseline_artifact(root:, name:, map:, installer:)
        bytes = JSON.generate("schema" => "ace.execution-boot-baseline/v1",
          "slot_id" => map.fetch("execution_scope").fetch("slot_id"), "boot_id" => ExecutionScopeObservationFixtures::BOOT,
          "deployment_digest" => Digest::SHA256.hexdigest(JSON.generate(Authority::LaunchLifecycle.allocate.send(:canonical, map))),
          "host_ipc_namespace_identity" => {"device" => 4, "inode" => 900},
          "original_host_context" => {"pid" => 1, "uid" => 0, "gid" => 0, "started_at" => "linux:#{ExecutionScopeObservationFixtures::BOOT}:1"},
          "producer_artifact" => installer)
        path = File.join(root, name)
        File.binwrite(path, bytes)
        {"path" => path, "sha256" => Digest::SHA256.hexdigest(bytes), "bytes" => bytes.bytesize}
      end

      def fixture_boot_baseline_reader(protection:, pointers: {})
        artifacts = Ace::Runtime::Molecules::ProtectedArtifactSet.allocate
        artifacts.send(:initialize, protection: protection)
        read = artifacts.method(:read_path!)
        artifacts.define_singleton_method(:read_path!) { |path, limit:| read.call(pointers.fetch(path, path), limit: limit) }
        reader = Ace::Runtime::Molecules::ExecutionBootBaseline.allocate
        reader.send(:initialize, artifacts: artifacts)
        reader
      end
    end
  end
end

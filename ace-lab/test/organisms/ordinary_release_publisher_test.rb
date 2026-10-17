# frozen_string_literal: true

require_relative "../test_helper"
require "ace/lab/organisms/ordinary_release_publisher"
require "ace/lab/organisms/ordinary_release_staging"

module Ace
  module Lab
    class OrdinaryReleasePublisherTest < Minitest::Test
      Staging = Organisms::OrdinaryReleaseStaging

      class FakeClient
        attr_accessor :calls, :results
        def initialize(results = [])
          @calls = []
          @results = results.dup
        end

        def run(argv:, executor:, services:)
          @calls << {argv: argv, executor: executor, services: services}
          outcome = @results.shift
          outcome.is_a?(StandardError) ? raise(outcome) : outcome
        end
      end

      def policy_document
        {"version" => 1, "projects" => {"atlas" => {
          "launcher" => {"socket_path" => "/run/ace/launcher.sock", "identity_path" => "/etc/lab/identity.json"},
          "default_executor" => "publisher", "default_services" => [],
          "executors" => {"publisher" => {"uid" => 15000, "gid" => 15000, "groups" => [15000],
            "home" => "/var/lib/publisher", "cwd" => "/var/lib/publisher", "path" => ["/usr/bin", "/bin"],
            "environment" => {}}},
          "services" => {},
          "commands" => {"publish" => {"argv" => ["/usr/local/bin/publish-from", "/var/stage"],
            "executable_sha256" => "a" * 64, "source" => {"head" => nil, "tree" => nil}, "purpose" => "command"}},
          "grants" => [{"kind" => "operator", "uid" => 41001, "command" => "publish",
            "executor" => "publisher", "services" => []}]
        }}}
      end

      def entry(id, name, state, bytes)
        {"name" => name, "version" => "1.0.0", "artifact_digest" => "d" * 64,
          "state" => state, "artifact_id" => id, "bytes" => bytes}
      end

      def staged(*entries)
        map = entries.to_h { |e| [e.fetch("artifact_id"), e] }
        Staging::State.new(map, entries.map { |e| e.fetch("artifact_id") }, [])
      end

      def test_materializes_only_unsettled_artifacts_into_the_policy_root
        Dir.mktmpdir("publisher-") do |dir|
          root = File.join(dir, "var", "stage")
          set = staged(entry("a", "gem-a", "pending", "AAA"),
            entry("b", "gem-b", "published", "BBB"),
            entry("c", "gem-c", "uncertain", "CCC"))
          publisher = Organisms::OrdinaryReleasePublisher.new(project: "atlas",
            policy: Molecules::CommandPolicy.new(policy_document, project: "atlas"), client: FakeClient.new)
          publisher.materialize(set, root)
          assert_equal "AAA", File.binread(File.join(root, "gem-a-1.0.0.gem"))
          assert_equal "CCC", File.binread(File.join(root, "gem-c-1.0.0.gem"))
          refute File.exist?(File.join(root, "gem-b-1.0.0.gem")), "published artifacts need no bytes"
          assert_equal 0o600, File.stat(File.join(root, "gem-a-1.0.0.gem")).mode & 0o777
        end
      end

      def test_publish_runs_the_pinned_argv_under_the_granted_executor
        client = FakeClient.new([0])
        publisher = Organisms::OrdinaryReleasePublisher.new(project: "atlas",
          policy: Molecules::CommandPolicy.new(policy_document, project: "atlas"), client: client)
        result = publisher.publish(name: "gem-a", version: "1.0.0")
        assert_equal 0, result.fetch(:exit_status)
        assert_nil result.fetch(:signal)
        call = client.calls.first
        assert_equal ["/usr/local/bin/publish-from", "/var/stage"], call.fetch(:argv)
        assert_equal "publisher", call.fetch(:executor)
      end

      def test_lost_channel_maps_to_unknown_never_success
        client = FakeClient.new([SystemCallError.new("channel gone")])
        publisher = Organisms::OrdinaryReleasePublisher.new(project: "atlas",
          policy: Molecules::CommandPolicy.new(policy_document, project: "atlas"), client: client)
        result = publisher.publish(name: "gem-a", version: "1.0.0")
        assert_nil result.fetch(:exit_status)
        assert_equal "unknown", result.fetch(:signal)
      end

      def test_missing_publish_command_refuses_precisely
        document = policy_document
        document["projects"]["atlas"]["commands"] = {}
        document["projects"]["atlas"]["grants"] = []
        publisher = Organisms::OrdinaryReleasePublisher.new(project: "atlas",
          policy: Molecules::CommandPolicy.new(document, project: "atlas"), client: FakeClient.new)
        error = assert_raises(ArgumentError) { publisher.publish(name: "x", version: "1") }
        assert_includes error.message, "no publish command"
      end
    end
  end
end

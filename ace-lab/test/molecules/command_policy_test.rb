# frozen_string_literal: true
require_relative "../test_helper"
require "ace/lab/molecules/command_policy"
module Ace
  module Lab
    class CommandPolicyTest < Minitest::Test
      def document
        {"version" => 1, "projects" => {"ace" => {
          "launcher" => {"socket_path" => "/run/lab/labd.sock", "identity_path" => "/run/lab/labd-identity.json"},
          "default_executor" => "publisher", "default_services" => [],
          "executors" => {"publisher" => {"uid" => 1002, "gid" => 1002, "groups" => [], "home" => "/var/empty", "cwd" => "/opt/accepted", "path" => ["/usr/bin", "/bin"], "environment" => {"LANG" => "C.UTF-8"}}},
          "services" => {"forge" => {"environment" => {"FORGE_URL" => "https://forge.invalid"}, "secret_references" => {}}, "rubygems" => {"environment" => {}, "secret_references" => {"GEM_CREDENTIALS" => "/etc/lab/secrets/rubygems"}}},
          "commands" => {"probe" => {"purpose" => "command", "argv" => ["/usr/bin/id"], "executable_sha256" => "a" * 64, "source" => {"head" => nil, "tree" => nil}}},
          "grants" => [{"kind" => "operator", "uid" => 1000, "command" => "probe", "executor" => "publisher", "services" => []}, {"kind" => "agent", "uid" => 1000, "command" => "probe", "executor" => "publisher", "services" => %w[forge rubygems]}]}}}
      end
      def select(policy, **options)
        policy.select(selection: {"argv" => ["/usr/bin/id"], "executor" => nil, "services" => nil, "pane" => nil}.merge(options.transform_keys(&:to_s)), peer: {"uid" => 1000, "pid" => 12, "started_at" => "actual"})
      end
      def test_test_purpose_requires_explicit_policy_and_exact_source
        source = document
        command = source.fetch("projects").fetch("ace").fetch("commands").fetch("probe")
        command.delete("purpose")
        assert_raises(InvalidConfigurationError) { Molecules::CommandPolicy.new(source, project: "ace") }
        command["purpose"] = "test"
        assert_raises(InvalidConfigurationError) { Molecules::CommandPolicy.new(source, project: "ace") }
        command["source"] = {"head" => "a" * 40, "tree" => "b" * 40}
        assert_equal "test", select(Molecules::CommandPolicy.new(source, project: "ace")).fetch("purpose")
        command["purpose"] = "inferred-from-argv"
        assert_raises(InvalidConfigurationError) { Molecules::CommandPolicy.new(source, project: "ace") }
      end

      def test_defaults_distinguish_operator_and_agent
        policy = Molecules::CommandPolicy.new(document, project: "ace")
        result = select(policy)
        assert_equal "operator", result.fetch("requester_kind")
        assert_equal [], result.fetch("services")
        assert_equal 1002, result.dig("executor", "uid")
        assert_equal({"LANG" => "C.UTF-8"}, result.dig("executor", "environment"))
        assert_equal({}, result.fetch("secret_references"))
        assert_raises(SecurityError) { select(policy, pane: "w1:p1") }
      end
      def test_dynamic_test_requires_closed_canonical_reference_without_caller_paths_or_head
        source = document
        command = source.fetch("projects").fetch("ace").fetch("commands").fetch("probe")
        command["purpose"] = "test"
        command["source"] = {"kind" => "ordinary-candidate", "root" => "/var/lib/lab/views",
          "runtime_path" => "/etc/lab/ace-lab/test-runtime.json", "runtime_sha256" => "c" * 64}
        policy = Molecules::CommandPolicy.new(source, project: "ace")
        reference = {"assignment_id" => "delivery", "attempt_id" => "worker1", "candidate_generation" => 1, "acceptance_event_digest" => "d" * 64}
        assert_equal reference, select(policy, candidate: reference).dig("selection", "candidate")
        assert_raises(InvalidConfigurationError) { select(policy) }
        assert_raises(InvalidConfigurationError) { select(policy, candidate: reference.merge("head" => "e" * 40)) }
        assert_raises(InvalidConfigurationError) { select(policy, candidate: reference.merge("path" => "/caller/source")) }
        assert_raises(InvalidConfigurationError) { select(policy, candidate: reference.merge("candidate_generation" => 0)) }
        assert_raises(InvalidConfigurationError) { select(Molecules::CommandPolicy.new(document, project: "ace"), candidate: reference) }
        command["purpose"] = "command"
        assert_raises(InvalidConfigurationError) { Molecules::CommandPolicy.new(source, project: "ace") }
      end
      def test_replacement_deduplication_and_whole_combination
        source = document
        source["projects"]["ace"]["default_services"] = ["forge"]
        policy = Molecules::CommandPolicy.new(source, project: "ace")
        result = select(policy, pane: "w1:p1", services: %w[rubygems forge forge])
        assert_equal %w[forge rubygems], result.fetch("services")
        assert_equal "/etc/lab/secrets/rubygems", result.dig("secret_references", "GEM_CREDENTIALS")
        assert_raises(SecurityError) { select(policy, pane: "w1:p1", services: ["forge"]) }
        assert_raises(SecurityError) { select(policy) }
        assert_equal [], select(policy, services: []).fetch("services")
      end
      def test_unknown_denied_and_ambiguous_selection
        policy = Molecules::CommandPolicy.new(document, project: "ace")
        assert_raises(SecurityError) { select(policy, executor: "root") }
        assert_raises(InvalidConfigurationError) { select(policy, services: ["unknown"]) }
        assert_raises(SecurityError) { select(policy, argv: ["/bin/sh", "-c", "id"]) }
        source = document
        source["projects"]["ace"]["commands"]["second"] = source["projects"]["ace"]["commands"]["probe"].dup
        assert_raises(SecurityError) { select(Molecules::CommandPolicy.new(source, project: "ace")) }
      end
      def test_environment_conflicts_injection_and_detached_input
        source = document
        policy = Molecules::CommandPolicy.new(source, project: "ace")
        source["projects"]["ace"]["executors"]["publisher"]["uid"] = 0
        assert_equal 1002, select(policy).dig("executor", "uid")
        source = document
        source["projects"]["ace"]["services"]["forge"]["environment"] = {"LANG" => "other"}
        policy = Molecules::CommandPolicy.new(source, project: "ace")
        assert_raises(SecurityError) { select(policy, pane: "w1:p1", services: %w[forge rubygems]) }
        %w[PATH RUBYOPT LD_PRELOAD BUNDLE_GEMFILE GIT_CONFIG_COUNT].each do |name|
          source = document
          source["projects"]["ace"]["executors"]["publisher"]["environment"][name] = "injection"
          assert_raises(InvalidConfigurationError) { Molecules::CommandPolicy.new(source, project: "ace") }
        end
      end
    end
  end
end

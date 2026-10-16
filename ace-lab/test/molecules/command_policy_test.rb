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
          "commands" => {"probe" => {"argv" => ["/usr/bin/id"], "executable_sha256" => "a" * 64, "source" => {"head" => nil, "tree" => nil}}},
          "grants" => [{"kind" => "operator", "uid" => 1000, "command" => "probe", "executor" => "publisher", "services" => []}, {"kind" => "agent", "uid" => 1000, "command" => "probe", "executor" => "publisher", "services" => %w[forge rubygems]}]}}}
      end
      def select(policy, **options)
        policy.select(selection: {"argv" => ["/usr/bin/id"], "executor" => nil, "services" => nil, "pane" => nil}.merge(options.transform_keys(&:to_s)), peer: {"uid" => 1000, "pid" => 12, "started_at" => "actual"})
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

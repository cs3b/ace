# frozen_string: true

require_relative "../test_helper"
require "ace/hitl/molecules/hitl_route_loader"

module Molecules
  # FINAL-LAB2 (PR #393 final audit): the manifest's `kind: hitl`
  # adapter declarations must become the runtime route configuration
  # ace-hitl actually reads (`hitl.adapters.routes` in the project's
  # `.ace/hitl/config.yml`). The written document is cross-checked
  # against the REAL runtime loader so the mirrored validation can
  # never drift from the contract.
  class HitlRoutesTest < Minitest::Test
    def organism
      Ace::Lab::Molecules::HitlRoutes.new
    end

    def adapters(config = {})
      [{"id" => "console", "kind" => "hitl", "command" => nil, "config" => config}]
    end

    def test_expected_routes_project_hitl_declarations_only
      declared = adapters("runtime" => "tmux") +
        [{"id" => "hermes", "kind" => "communication", "command" => "ace-hitl-hermes", "config" => {}}]

      assert_equal [{"adapter" => "console", "runtime" => "tmux"}],
        Ace::Lab::Molecules::HitlRoutes.expected_routes(declared)
    end

    def test_install_writes_the_runtime_route_configuration
      Dir.mktmpdir do |root|
        report = organism.install(root: root, adapters: adapters("runtime" => "tmux"))

        assert_equal "created", report["status"], report.inspect
        path = File.join(root, ".ace", "hitl", "config.yml")
        document = YAML.safe_load_file(path)
        assert_equal [{"adapter" => "console", "runtime" => "tmux"}],
          document.dig("hitl", "adapters", "routes")
        # the real runtime loader accepts the written document
        routes = Ace::Hitl::Molecules::HitlRouteLoader.load(document)
        assert_equal "console", routes.first["route"]
        assert_equal "console", routes.first["adapter"]
      end
    end

    def test_re_install_with_unchanged_declarations_is_a_no_op
      Dir.mktmpdir do |root|
        organism.install(root: root, adapters: adapters)
        path = File.join(root, ".ace", "hitl", "config.yml")
        stat = File.stat(path)

        report = organism.install(root: root, adapters: adapters)

        assert_equal "exists", report["status"], report.inspect
        assert_equal stat.ino, File.stat(path).ino
        document = YAML.safe_load_file(path)
        assert_equal [{"adapter" => "console"}], document.dig("hitl", "adapters", "routes")
        # and the real loader still loads it
        refute_nil Ace::Hitl::Molecules::HitlRouteLoader.load(document)
      end
    end

    def test_configuration_changes_replace_the_route_by_name
      Dir.mktmpdir do |root|
        organism.install(root: root, adapters: adapters)
        report = organism.install(root: root, adapters: adapters("runtime" => "screen"))

        assert_equal "created", report["status"], report.inspect
        document = YAML.safe_load_file(File.join(root, ".ace", "hitl", "config.yml"))
        assert_equal [{"adapter" => "console", "runtime" => "screen"}],
          document.dig("hitl", "adapters", "routes")
      end
    end

    def test_operator_owned_routes_and_settings_survive
      Dir.mktmpdir do |root|
        path = File.join(root, ".ace", "hitl", "config.yml")
        FileUtils.mkdir_p(File.dirname(path))
        File.write(path, YAML.dump({
          "hitl" => {
            "root_dir" => ".ace-local/hitl",
            "adapters" => {"routes" => [{"adapter" => "terminal", "pane" => "p5"}]}
          }
        }))

        report = organism.install(root: root, adapters: adapters)

        assert_equal "created", report["status"], report.inspect
        document = YAML.safe_load_file(path)
        assert_equal [{"adapter" => "terminal", "pane" => "p5"}, {"adapter" => "console"}],
          document.dig("hitl", "adapters", "routes")
        assert_equal ".ace-local/hitl", document.dig("hitl", "root_dir")
        refute_nil Ace::Hitl::Molecules::HitlRouteLoader.load(document)
      end
    end

    def test_without_hitl_adapters_the_step_is_skipped
      Dir.mktmpdir do |root|
        report = organism.install(root: root, adapters: [])

        assert_equal "skipped", report["status"]
        refute File.exist?(File.join(root, ".ace", "hitl", "config.yml"))
      end
    end

    def test_dry_run_predicts_without_writing
      Dir.mktmpdir do |root|
        report = organism.install(root: root, adapters: adapters, dry_run: true)

        assert_equal "would_create", report["status"]
        refute File.exist?(File.join(root, ".ace", "hitl", "config.yml"))
      end
    end

    def test_unparseable_existing_document_is_refused
      Dir.mktmpdir do |root|
        path = File.join(root, ".ace", "hitl", "config.yml")
        FileUtils.mkdir_p(File.dirname(path))
        File.write(path, "---\nhitl: [unclosed\n\tbroken")

        report = organism.install(root: root, adapters: adapters)

        assert_equal "failed", report["status"]
        assert_match(/could not be parsed as YAML/, report["message"])
      end
    end

    # --- validation mirrors the runtime loader contract ---------------

    def test_validation_reason_matches_the_runtime_loader_rules
      nil_reason = ->(routes) { Ace::Lab::Molecules::HitlRoutes.validation_reason(routes) }

      assert_nil nil_reason.call([{"adapter" => "terminal"}])
      assert_match(/non-empty list/, nil_reason.call(nil))
      assert_match(/non-empty list/, nil_reason.call([]))
      assert_match(/must be a mapping/, nil_reason.call(["terminal"]))
      assert_match(/missing required 'adapter'/, nil_reason.call([{"route" => "x"}]))
      assert_match(/route name 'a\.b' is invalid/, nil_reason.call([{"adapter" => "a.b"}]))
      assert_match(/duplicate route name\(s\) terminal/,
        nil_reason.call([{"adapter" => "terminal"}, {"adapter" => "terminal", "route" => "terminal"}]))
    end

    def test_config_reason_reports_missing_invalid_and_absent_routes
      expected = {"adapter" => "console"}
      Dir.mktmpdir do |root|
        assert_match(/is missing/, Ace::Lab::Molecules::HitlRoutes.config_reason(root: root, expected: expected))

        path = File.join(root, ".ace", "hitl", "config.yml")
        FileUtils.mkdir_p(File.dirname(path))
        File.write(path, YAML.dump({"hitl" => {"adapters" => {"routes" => [{"adapter" => "other"}]}}}))
        assert_match(/is not configured/, Ace::Lab::Molecules::HitlRoutes.config_reason(root: root, expected: expected))

        File.write(path, YAML.dump({"hitl" => {"adapters" => {"routes" => [expected]}}}))
        assert_nil Ace::Lab::Molecules::HitlRoutes.config_reason(root: root, expected: expected)
      end
    end
  end
end

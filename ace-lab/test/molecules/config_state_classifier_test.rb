# frozen_string_literal: true

require "test_helper"

module Ace
  module Lab
    module Molecules
      class ConfigStateClassifierTest < Minitest::Test
        def defaults_document(path: "/gem/.ace-defaults/lab/config.yml")
          {path: path, document: {"schema_version" => 1, "topology": {"projects" => [], "agents" => [], "services" => []}}, defaults: true}
        end

        def overlay_document(path:, document:)
          {path: path, document: document, defaults: false}
        end

        def classify(documents, cascade_error: nil)
          ConfigStateClassifier.classify(documents: documents, cascade_error: cascade_error, root: "/tmp")
        end

        def test_no_overlay_means_defaults_only_missing_configuration
          result = classify([defaults_document])

          assert_equal :defaults_only, result[:state]
          assert_nil result[:error]
        end

        def test_empty_overlay_is_configured_with_valid_empty_set
          result = classify([
            overlay_document(path: "/project/.ace/lab/config.yml", document: {"topology" => {}}),
            defaults_document
          ])

          assert_equal :configured, result[:state]
          assert_equal({projects: 0, agents: 0, services: 0}, result[:topology])
        end

        def test_overlay_counts_topology_entries
          overlay = {
            "topology" => {
              "projects" => [{"id" => "atlas", "label" => "Atlas"}],
              "agents" => [{"id" => "a1", "project" => "atlas", "role" => "planner",
                            "capabilities" => ["planning"],
                            "binding" => {"kind" => "runtime", "state" => "active",
                                          "instance_id" => "iid", "attested_instance_id" => "iid"}}],
              "services" => [{"id" => "s1", "project" => "atlas", "capabilities" => ["search"],
                              "endpoint" => {"kind" => "https", "url" => "https://s1.example.com"},
                              "binding" => {"kind" => "service", "state" => "active"}}]
            }
          }
          result = classify([
            overlay_document(path: "/project/.ace/lab/config.yml", document: overlay),
            defaults_document
          ])

          assert_equal :configured, result[:state]
          assert_equal({projects: 1, agents: 1, services: 1}, result[:topology])
          assert_equal "/project/.ace/lab/config.yml", result[:source_path]
        end

        def test_cascade_error_is_invalid_with_message
          result = classify(nil, cascade_error: "invalid lab configuration: /project/.ace/lab/config.yml could not be parsed as YAML")

          assert_equal :invalid, result[:state]
          assert_includes result[:error], "could not be parsed"
        end

        def test_schema_violation_is_invalid_not_raised
          result = classify([
            overlay_document(path: "/project/.ace/lab/config.yml", document: {"schema_version" => 99}),
            defaults_document
          ])

          assert_equal :invalid, result[:state]
          assert_includes result[:error], "schema_version"
        end

        def test_project_overlay_wins_over_user_overlay
          # cascade_documents order: highest priority first (project, user,
          # defaults) — same order the canonical ADR-22 resolver reduces in
          # reverse. The project topology must be the one in force.
          project_topology = {
            "projects" => [{"id" => "p1", "label" => "P1"}],
            "agents" => [],
            "services" => []
          }
          user_topology = {
            "projects" => [{"id" => "u1", "label" => "U1"}, {"id" => "u2", "label" => "U2"}],
            "agents" => [],
            "services" => []
          }
          result = classify([
            overlay_document(path: "/project/.ace/lab/config.yml", document: {"topology" => project_topology}),
            overlay_document(path: File.join(Dir.home, ".ace/lab/config.yml"), document: {"topology" => user_topology}),
            defaults_document
          ])

          assert_equal :configured, result[:state]
          assert_equal 1, result[:topology][:projects]
          assert_equal "/project/.ace/lab/config.yml", result[:source_path]
          assert_equal "/project/.ace/lab/config.yml", result[:overlays][:project]
          assert_equal File.join(Dir.home, ".ace/lab/config.yml"), result[:overlays][:user]
        end

        def test_project_rooted_under_home_is_still_the_project_overlay
          result = classify([
            overlay_document(path: File.join(Dir.home, "Ps/ace/.ace/lab/config.yml"),
                             document: {"topology" => {"projects" => [], "agents" => [], "services" => []}}),
            defaults_document
          ])

          assert_equal :configured, result[:state]
          assert_equal File.join(Dir.home, "Ps/ace/.ace/lab/config.yml"), result[:overlays][:project]
          assert_nil result[:overlays][:user]
        end

        def test_no_documents_at_all_is_missing_not_invalid
          result = classify([])

          assert_equal :defaults_only, result[:state]
          assert_nil result[:error]
        end

        def test_runtime_config_from_project_file
          Dir.mktmpdir do |tmp|
            FileUtils.mkdir_p(File.join(tmp, ".ace/runtime"))
            File.write(File.join(tmp, ".ace/runtime/config.yml"), "runtime: herdr\n")

            result = ConfigStateClassifier.runtime_config(root: tmp)

            assert_equal :valid, result[:state]
            assert_equal "herdr", result[:runtime]
            assert_equal "project", result[:source]
          end
        end

        def test_runtime_config_from_env_when_no_files
          result = nil
          Dir.mktmpdir do |tmp|
            ENV["ACE_RUNTIME"] = "tmux"
            result = ConfigStateClassifier.runtime_config(root: tmp)
            ENV.delete("ACE_RUNTIME")
          end

          assert_equal :valid, result[:state]
          assert_equal "tmux", result[:runtime]
          assert_equal "env", result[:source]
        end

        def test_unparseable_runtime_config_is_invalid
          Dir.mktmpdir do |tmp|
            FileUtils.mkdir_p(File.join(tmp, ".ace/runtime"))
            File.write(File.join(tmp, ".ace/runtime/config.yml"), "runtime: [unclosed\n")

            result = ConfigStateClassifier.runtime_config(root: tmp)

            assert_equal :invalid, result[:state]
            assert_includes result[:error], "could not be parsed"
          end
        end

        def test_runtime_config_absent
          Dir.mktmpdir do |tmp|
            ENV.delete("ACE_RUNTIME")

            result = ConfigStateClassifier.runtime_config(root: tmp)

            assert_equal :absent, result[:state]
            assert_nil result[:runtime]
          end
        end
      end
    end
  end
end

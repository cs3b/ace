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
            defaults_document,
            overlay_document(path: "/project/.ace/lab/config.yml", document: {"topology" => {}})
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
            defaults_document,
            overlay_document(path: "/project/.ace/lab/config.yml", document: overlay)
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
            defaults_document,
            overlay_document(path: "/project/.ace/lab/config.yml", document: {"schema_version" => 99})
          ])

          assert_equal :invalid, result[:state]
          assert_includes result[:error], "schema_version"
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

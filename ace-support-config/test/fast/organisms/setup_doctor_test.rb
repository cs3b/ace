# frozen_string_literal: true

require "test_helper"
require "stringio"
require "tmpdir"
require "fileutils"
require "ace/support/config/organisms/setup_doctor"

module Ace
  module Support
    module Config
      class SetupDoctorTest < TestCase
        def test_json_output_contains_equivalent_facts_and_blocking_exit_code
          with_temp_config(
            ".git" => {},
            ".gitignore" => "node_modules/\n",
            ".ace-local" => {}
          ) do
            doctor = Organisms::SetupDoctor.new
            io = StringIO.new

            doctor.stub(:check_provider_package, pass_check("provider-package", "package ok")) do
              doctor.stub(:check_provider_discovery, pass_check("provider-discovery", "discovery ok")) do
                doctor.stub(:load_provider_context, sample_provider_context) do
                  code = doctor.run(json: true, no_probe: true, io: io)
                  json = JSON.parse(io.string)

                  assert_equal 1, code
                  assert_equal 1, json["blocker_count"]
                  assert_equal 0, json["warning_count"]
                  assert_equal "artifact-hygiene", json.fetch("checks").first.fetch("id")
                  assert_equal "blocker", json.fetch("checks").first.fetch("status")
                end
              end
            end
          end
        end

        def test_no_probe_marks_probe_as_skip
          with_temp_config(
            ".git" => {},
            ".gitignore" => ".ace-local/\n"
          ) do
            doctor = Organisms::SetupDoctor.new
            io = StringIO.new

            doctor.stub(:check_provider_package, pass_check("provider-package", "package ok")) do
              doctor.stub(:check_provider_discovery, pass_check("provider-discovery", "discovery ok")) do
                doctor.stub(:load_provider_context, sample_provider_context) do
                  code = doctor.run(no_probe: true, io: io)

                  assert_equal 0, code
                  assert_includes io.string, "SKIP Live provider probes disabled by --no-probe"
                end
              end
            end
          end
        end

        def test_probe_warns_when_credentials_missing
          with_temp_config(
            ".git" => {},
            ".gitignore" => ".ace-local/\n"
          ) do
            doctor = Organisms::SetupDoctor.new
            io = StringIO.new

            provider_context = {
              providers: [
                {
                  name: "codex",
                  available: true,
                  api_key_required: true,
                  api_key_present: false,
                  models: ["gpt-5.4"]
                }
              ],
              aliases: {global: {}, model: {}},
              registry: Struct.new(:resolved) do
                def resolve_alias(value)
                  value
                end
              end.new
            }

            doctor.stub(:check_provider_package, pass_check("provider-package", "package ok")) do
              doctor.stub(:check_provider_discovery, pass_check("provider-discovery", "discovery ok")) do
                doctor.stub(:load_provider_context, provider_context) do
                  code = doctor.run(io: io)

                  assert_equal 0, code
                  assert_includes io.string, "WARN Some providers require credentials or local account access"
                end
              end
            end
          end
        end

        def test_alias_readiness_blocks_stale_alias
          with_temp_config(
            ".git" => {},
            ".gitignore" => ".ace-local/\n"
          ) do
            doctor = Organisms::SetupDoctor.new
            io = StringIO.new

            provider_context = {
              providers: [
                {
                  name: "codex",
                  available: true,
                  api_key_required: true,
                  api_key_present: false,
                  models: ["gpt-5.4", "gpt-5.4-mini"]
                }
              ],
              aliases: {
                global: {},
                model: {"codex" => {"old" => "gpt-5-mini"}}
              },
              registry: sample_provider_context[:registry]
            }

            doctor.stub(:check_provider_package, pass_check("provider-package", "package ok")) do
              doctor.stub(:check_provider_discovery, pass_check("provider-discovery", "discovery ok")) do
                doctor.stub(:load_provider_context, provider_context) do
                  code = doctor.run(io: io)

                  assert_equal 1, code
                  assert_includes io.string, "BLOCKER Unsupported alias mappings detected"
                  assert_includes io.string, "codex:old -> gpt-5-mini"
                end
              end
            end
          end
        end

        def test_alias_readiness_blocks_stale_global_alias_target
          with_temp_config(
            ".git" => {},
            ".gitignore" => ".ace-local/\n"
          ) do
            doctor = Organisms::SetupDoctor.new
            io = StringIO.new

            provider_context = {
              providers: [
                {
                  name: "codex",
                  available: true,
                  api_key_required: true,
                  api_key_present: true,
                  models: ["gpt-5.4", "gpt-5.4-mini"]
                }
              ],
              aliases: {
                global: {"codex:legacy" => "codex:gpt-5-mini"},
                model: {}
              },
              registry: sample_provider_context[:registry]
            }

            doctor.stub(:check_provider_package, pass_check("provider-package", "package ok")) do
              doctor.stub(:check_provider_discovery, pass_check("provider-discovery", "discovery ok")) do
                doctor.stub(:load_provider_context, provider_context) do
                  code = doctor.run(io: io)

                  assert_equal 1, code
                  assert_includes io.string, "BLOCKER Unsupported alias mappings detected"
                  assert_includes io.string, "codex:codex:legacy -> gpt-5-mini"
                end
              end
            end
          end
        end

        def test_artifact_hygiene_accepts_semantic_ace_local_patterns
          with_temp_config(
            ".git" => {},
            ".gitignore" => "/.ace-local/\n.ace-local/**\n"
          ) do
            doctor = Organisms::SetupDoctor.new
            io = StringIO.new

            doctor.stub(:check_provider_package, pass_check("provider-package", "package ok")) do
              doctor.stub(:check_provider_discovery, pass_check("provider-discovery", "discovery ok")) do
                doctor.stub(:load_provider_context, sample_provider_context) do
                  code = doctor.run(no_probe: true, io: io)

                  assert_equal 0, code
                  assert_includes io.string, "PASS .ace-local/ is ignored"
                end
              end
            end
          end
        end

        def test_provider_package_check_reports_missing_cli_gem
          doctor = Organisms::SetupDoctor.new
          Gem::Specification.stub(:find_all_by_name, []) do
            check = doctor.send(:check_provider_package)
            assert_equal "blocker", check[:status]
            assert_includes check[:message], "ace-llm-providers-cli"
            assert_includes check[:next_action], "bundle install"
          end
        end

        private

        def pass_check(id, message)
          {id: id, status: "pass", message: message, next_action: nil}
        end

        def sample_provider_context
          registry = Struct.new(:resolved) do
            def resolve_alias(name)
              resolved.fetch(name, name)
            end
          end.new({"codex:gpt" => "codex:gpt-5.4"})

          {
            providers: [
              {
                name: "codex",
                available: true,
                api_key_required: true,
                api_key_present: true,
                models: ["gpt-5.4"]
              }
            ],
            aliases: {
              global: {"codex:gpt" => "codex:gpt-5.4"},
              model: {"codex" => {"gpt" => "gpt-5.4"}}
            },
            registry: registry
          }
        end
      end
    end
  end
end

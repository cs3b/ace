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
                  doctor.stub(:check_role_health, pass_role_check) do
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
                  doctor.stub(:check_role_health, pass_role_check) do
                    code = doctor.run(no_probe: true, colors: false, io: io)

                    assert_equal 0, code
                    assert_includes io.string, "○ Live provider probes disabled by --no-probe"
                  end
                end
              end
            end
          end
        end

        def test_default_doctor_runs_live_provider_checks
          with_temp_config(
            ".git" => {},
            ".gitignore" => ".ace-local/\n"
          ) do
            doctor = Organisms::SetupDoctor.new
            io = StringIO.new
            pinged = []

            doctor.stub(:check_provider_package, pass_check("provider-package", "package ok")) do
              doctor.stub(:check_provider_discovery, pass_check("provider-discovery", "discovery ok")) do
                doctor.stub(:load_provider_context, sample_provider_context) do
                  doctor.stub(:check_role_health, pass_role_check) do
                    doctor.stub(:utility_provider_targets, [{role: "utility", provider: "codex", model: "gpt-5.4-mini", selector: "codex:gpt-5.4-mini", label: "codex:mini"}]) do
                      doctor.stub(:run_probe_targets, ->(targets, **_kwargs) { pinged.concat(targets); [{status: "pass", selector: "codex:gpt-5.4-mini", elapsed_ms: 1}] }) do
                        code = doctor.run(colors: false, io: io)

                        assert_equal 0, code
                        assert_equal ["codex:mini"], pinged.map { |target| target[:label] }
                        assert_includes io.string, "RUN Utility provider pings running"
                        assert_includes io.string, "✓ Utility provider pings completed (1/1 passed)"
                      end
                    end
                  end
                end
              end
            end
          end
        end

        def test_probe_uses_deduped_utility_and_commit_targets
          with_temp_config(
            ".git" => {},
            ".gitignore" => ".ace-local/\n"
          ) do
            doctor = Organisms::SetupDoctor.new
            io = StringIO.new
            probed = []
            targets = [
              {role: "utility", provider: "codex", model: "gpt-5.4-mini", label: "codex:mini"},
              {role: "utility", provider: "gemini", model: "gemini-2.5-flash", label: "gemini:flash-latest"},
              {role: "utility", provider: "codex", model: "gpt-5.4", label: "codex:gpt"}
            ]

            doctor.stub(:check_provider_package, pass_check("provider-package", "package ok")) do
              doctor.stub(:check_provider_discovery, pass_check("provider-discovery", "discovery ok")) do
                doctor.stub(:load_provider_context, sample_provider_context) do
                  doctor.stub(:check_role_health, pass_role_check) do
                    doctor.stub(:utility_provider_targets, targets) do
                      doctor.stub(:run_probe_targets, ->(ping_targets, **_kwargs) { probed.concat(ping_targets); [{status: "pass", selector: "codex:gpt-5.4-mini", elapsed_ms: 1}] }) do
                        code = doctor.run(probe: true, colors: false, io: io)

                        assert_equal 0, code
                        assert_equal ["codex:gpt-5.4-mini", "gemini:gemini-2.5-flash"], probed.map { |target| "#{target[:provider]}:#{target[:model]}" }
                        assert_includes io.string, "RUN Utility provider pings running"
                        assert_includes io.string, "✓ Utility provider pings completed (1/1 passed)"
                      end
                    end
                  end
                end
              end
            end
          end
        end

        def test_probe_targets_use_normal_no_fallback_query
          doctor = Organisms::SetupDoctor.new
          captured = []
          status = Object.new
          def status.success? = true

          Open3.stub(:capture3, ->(*args) { captured << args; ["pong", "", status] }) do
            outcomes = doctor.send(
              :run_probe_targets,
              [{role: "utility", provider: "codex", model: "gpt-5.4-mini", selector: "codex:gpt-5.4-mini", label: "codex:mini"}]
            )

            assert_equal "pass", outcomes.first[:status]
          end

          assert_equal [
            [
              "ace-llm",
              "codex:mini",
              "ping",
              "--no-fallback",
              "--quiet",
              "--timeout",
              "15",
              "--max-tokens",
              "4"
            ]
          ], captured
        end

        def test_probe_targets_use_cli_and_api_timeouts
          doctor = Organisms::SetupDoctor.new
          captured = []
          status = Object.new
          def status.success? = true

          Open3.stub(:capture3, ->(*args) { captured << args; ["pong", "", status] }) do
            outcomes = doctor.send(
              :run_probe_targets,
              [
                {role: "utility", provider: "codex", model: "gpt-5.4-mini", selector: "codex:gpt-5.4-mini", label: "codex:mini", provider_kind: "cli", timeout_seconds: 30},
                {role: "utility", provider: "google", model: "gemini-flash-lite-latest", selector: "google:gemini-flash-lite-latest", label: "glite", provider_kind: "api", timeout_seconds: 15}
              ]
            )

            assert_equal %w[pass pass], outcomes.map { |outcome| outcome[:status] }
          end

          assert_equal ["30", "15"], captured.map { |args| args[args.index("--timeout") + 1] }
        end

        def test_probe_readiness_orders_api_targets_before_cli_targets
          doctor = Organisms::SetupDoctor.new
          targets = [
            {role: "utility", provider: "codex", model: "gpt-5.4-mini", selector: "codex:gpt-5.4-mini", label: "codex:mini"},
            {role: "utility", provider: "google", model: "gemini-flash-lite-latest", selector: "google:gemini-flash-lite-latest", label: "glite"}
          ]
          probed = []

          doctor.stub(:run_probe_targets, ->(ordered, **_kwargs) {
            probed.concat(ordered)
            ordered.map { |target| {status: "pass", selector: target[:selector], label: target[:label]} }
          }) do
            check = doctor.send(
              :check_probe_readiness,
              provider_context_with_kinds("codex" => "cli", "google" => "api"),
              no_probe: false,
              probe: false,
              role_targets: targets,
              structural_blockers: false
            )

            assert_equal "pass", check[:status]
          end

          assert_equal ["glite", "codex:mini"], probed.map { |target| target[:label] }
          assert_equal [15, 30], probed.map { |target| target[:timeout_seconds] }
        end

        def test_probe_readiness_reports_partial_success_as_warning_with_counts
          doctor = Organisms::SetupDoctor.new
          targets = [
            {role: "utility", provider: "codex", model: "gpt-5.4-mini", selector: "codex:gpt-5.4-mini", label: "codex:mini"},
            {role: "utility", provider: "gemini", model: "gemini-2.5-flash", selector: "gemini:gemini-2.5-flash", label: "gemini:flash-latest"}
          ]
          outcomes = [
            {status: "pass", selector: "codex:gpt-5.4-mini", label: "codex:mini", elapsed_ms: 3},
            {status: "warn", selector: "gemini:gemini-2.5-flash", label: "gemini:flash-latest", next_action: "Authenticate provider."}
          ]

          doctor.stub(:run_probe_targets, ->(_targets, **_kwargs) { outcomes }) do
            check = doctor.send(
              :check_probe_readiness,
              sample_provider_context,
              no_probe: false,
              probe: false,
              role_targets: targets,
              structural_blockers: false
            )

            assert_equal "warn", check[:status]
            assert_equal "Utility provider pings partially completed (1/2 passed)", check[:message]
            assert_includes check[:next_action], "At least one utility provider works"
            assert_includes check[:details], "codex:mini (codex:gpt-5.4-mini) responded in 3ms"
            assert_includes check[:details], "gemini:flash-latest (gemini:gemini-2.5-flash) failed"
          end
        end

        def test_terminal_report_marks_failed_provider_rows_with_cross
          output = Molecules::SetupDoctorReporter.format_results(
            {
              valid: true,
              duration: 0.1,
              health: {blocker_count: 0, warning_count: 1},
              hygiene: {finding_count: 0, warning_count: 0, blocker_count: 0},
              stats: {health_checks: 1, provider_targets: 2, hygiene_findings: 0},
              checks: [
                {
                  id: "probe-readiness",
                  kind: "health",
                  status: "warn",
                  message: "Utility provider pings partially completed (1/2 passed)",
                  outcomes: [
                    {status: "pass", label: "codex:mini", selector: "codex:gpt-5.4-mini", elapsed_ms: 2},
                    {status: "warn", label: "glite", selector: "google:gemini-flash-lite-latest"}
                  ]
                }
              ]
            },
            colors: false
          )

          assert_includes output, "○ Utility provider pings partially completed (1/2 passed)"
          assert_includes output, "✓ codex:mini (codex:gpt-5.4-mini) in 2ms"
          assert_includes output, "✗ glite (google:gemini-flash-lite-latest)"
        end

        def test_terminal_report_distinguishes_provider_timeout_rows
          output = Molecules::SetupDoctorReporter.format_results(
            {
              valid: true,
              duration: 0.1,
              health: {blocker_count: 0, warning_count: 1},
              info: {count: 0},
              hygiene: {finding_count: 0, warning_count: 0, blocker_count: 0},
              stats: {health_checks: 1, info_checks: 0, provider_targets: 1, hygiene_findings: 0},
              checks: [
                {
                  id: "probe-readiness",
                  kind: "health",
                  status: "warn",
                  message: "Utility provider pings failed (0/1 passed)",
                  outcomes: [
                    {
                      status: "warn",
                      label: "gemini:flash-latest",
                      selector: "gemini:gemini-3-flash-preview",
                      failure_type: "timeout",
                      timeout_seconds: 30
                    }
                  ]
                }
              ]
            },
            colors: false
          )

          assert_includes output, "✗ gemini:flash-latest (gemini:gemini-3-flash-preview) timed out after 30s"
        end

        def test_config_defaults_reports_info_counts_for_customized_and_default_files
          Dir.mktmpdir do |tmpdir|
            source_dir = File.join(tmpdir, "ace-demo", ".ace-defaults")
            FileUtils.mkdir_p(File.join(source_dir, "demo"))
            File.write(File.join(source_dir, "demo", "a.yml"), "a: 1\n")
            File.write(File.join(source_dir, "demo", "b.yml"), "b: 1\n")

            project_dir = File.join(tmpdir, "project")
            FileUtils.mkdir_p(File.join(project_dir, ".ace", "demo"))
            File.write(File.join(project_dir, ".gitignore"), ".ace-local/\n")
            FileUtils.mkdir_p(File.join(project_dir, ".git"))
            File.write(File.join(project_dir, ".ace", "demo", "a.yml"), "a: 2\n")

            Dir.chdir(project_dir) do
              doctor = Organisms::SetupDoctor.new
              Models::ConfigTemplates.stub(:all_gems, ["ace-demo"]) do
                Models::ConfigTemplates.stub(:example_dir_for, ->(_gem_name) { source_dir }) do
                  check = doctor.send(:check_config_defaults)

                  assert_equal "info", check[:status]
                  assert_equal "info", check[:kind]
                  assert_includes check[:message], "1 customized, 1 default"
                  assert_equal 1, check.fetch(:summary).fetch(:customized)
                  assert_equal 1, check.fetch(:summary).fetch(:default)
                end
              end
            end
          end
        end

        def test_skill_sync_reports_warning_when_provider_projection_is_missing
          doctor = Organisms::SetupDoctor.new
          payload = {
            "canonical" => {"total" => 100},
            "providers" => [
              {"provider" => "codex", "expected" => 100, "installed" => 99, "in_sync" => 99, "outdated" => 0, "missing" => 1, "extra" => 0}
            ]
          }

          Open3.stub(:capture3, ->(*_args) { [JSON.generate(payload), "", command_status(true)] }) do
            check = doctor.send(:check_skill_sync)

            assert_equal "warn", check[:status]
            assert_includes check[:message], "Provider skill sync drift detected"
            assert_includes check[:details], "codex: 99/100 in sync, 1 missing, 0 outdated, 0 extra"
            assert_includes check[:next_action], "ace-handbook sync"
          end
        end

        def test_skill_sync_reports_pass_when_all_provider_projections_are_current
          doctor = Organisms::SetupDoctor.new
          payload = {
            "canonical" => {"total" => 100},
            "providers" => [
              {"provider" => "codex", "expected" => 100, "installed" => 100, "in_sync" => 100, "outdated" => 0, "missing" => 0, "extra" => 0}
            ]
          }

          Open3.stub(:capture3, ->(*_args) { [JSON.generate(payload), "", command_status(true)] }) do
            check = doctor.send(:check_skill_sync)

            assert_equal "pass", check[:status]
            assert_includes check[:message], "Provider skills are in sync"
          end
        end

        def test_agent_engineering_guidance_warns_when_docs_are_missing
          with_temp_config(
            ".git" => {},
            ".gitignore" => ".ace-local/\n",
            "AGENTS.md" => "# Repository Guidelines\n\nCost Bias Override\n"
          ) do
            doctor = Organisms::SetupDoctor.new

            check = doctor.send(:check_agent_engineering_guidance)

            assert_equal "warn", check[:status]
            assert_includes check[:details], "docs/tools.md is missing"
            assert_includes check[:next_action], "ace-config sync ace-support-core --force"
          end
        end

        def test_agent_engineering_guidance_warns_when_root_marker_is_missing
          with_temp_config(
            ".git" => {},
            ".gitignore" => ".ace-local/\n",
            "AGENTS.md" => "# Repository Guidelines\n",
            "docs" => {"tools.md" => "## Agent Engineering Practices\n"}
          ) do
            doctor = Organisms::SetupDoctor.new

            check = doctor.send(:check_agent_engineering_guidance)

            assert_equal "warn", check[:status]
            assert_includes check[:details], "AGENTS.md lacks Cost Bias Override"
          end
        end

        def test_agent_engineering_guidance_warns_when_root_link_anchor_is_missing
          with_temp_config(
            ".git" => {},
            ".gitignore" => ".ace-local/\n",
            "AGENTS.md" => "# Repository Guidelines\n\nCost Bias Override\nSee docs/tools.md#agent-engineering-practices\n",
            "docs" => {"tools.md" => "# Tools\n"}
          ) do
            doctor = Organisms::SetupDoctor.new

            check = doctor.send(:check_agent_engineering_guidance)

            assert_equal "warn", check[:status]
            assert_includes check[:details], "docs/tools.md lacks ## Agent Engineering Practices"
            assert_includes(
              check[:details],
              "root guidance links docs/tools.md#agent-engineering-practices but the anchor target is absent"
            )
          end
        end

        def test_agent_engineering_guidance_passes_when_markers_are_present
          with_temp_config(
            ".git" => {},
            ".gitignore" => ".ace-local/\n",
            "AGENTS.md" => "# Repository Guidelines\n\nCost Bias Override\nSee docs/tools.md#agent-engineering-practices\n",
            "CLAUDE.md" => "# CLAUDE.md\n\nCost Bias Override\nSee docs/tools.md#agent-engineering-practices\n",
            "docs" => {"tools.md" => "## Agent Engineering Practices\n"}
          ) do
            doctor = Organisms::SetupDoctor.new

            check = doctor.send(:check_agent_engineering_guidance)

            assert_equal "pass", check[:status]
            assert_includes check[:message], "Agent engineering guidance is present"
          end
        end

        def test_streaming_output_prints_fast_checks_before_provider_progress
          with_temp_config(
            ".git" => {},
            ".gitignore" => ".ace-local/\n"
          ) do
            doctor = Organisms::SetupDoctor.new
            io = StringIO.new

            doctor.stub(:check_provider_package, pass_check("provider-package", "package ok")) do
              doctor.stub(:check_provider_discovery, pass_check("provider-discovery", "discovery ok")) do
                doctor.stub(:check_config_defaults, {id: "config-defaults", kind: "info", status: "info", message: "config defaults info", summary: {customized: 0, default: 1}}) do
                  doctor.stub(:load_provider_context, sample_provider_context) do
                    doctor.stub(:check_role_health, pass_role_check) do
                      doctor.stub(:check_skill_sync, pass_check("skill-sync", "skills ok")) do
                        doctor.stub(:utility_provider_targets, [{role: "utility", provider: "codex", model: "gpt-5.4-mini", selector: "codex:gpt-5.4-mini", label: "codex:mini"}]) do
                          doctor.stub(:run_probe_targets, ->(targets, **_kwargs) { [{status: "pass", selector: targets.first[:selector], label: targets.first[:label]}] }) do
                            doctor.run(colors: false, io: io)
                          end
                        end
                      end
                    end
                  end
                end
              end
            end

            lines = io.string.lines.map(&:chomp)
            info_index = lines.index("INFO config defaults info")
            run_index = lines.index("RUN Utility provider pings running (0/1 passed)")
            report_index = lines.index("🏥 Setup Health Check")

            assert info_index
            assert run_index
            assert report_index
            assert_operator info_index, :<, run_index
            assert_operator run_index, :<, report_index
          end
        end

        def test_probe_progress_prints_pending_and_final_non_tty_lines
          doctor = Organisms::SetupDoctor.new
          io = StringIO.new
          progress = doctor.send(
            :provider_progress,
            io,
            [{label: "codex:mini", selector: "codex:gpt-5.4-mini"}]
          )

          progress.start
          progress.finish(0, {status: "pass", label: "codex:mini", selector: "codex:gpt-5.4-mini", elapsed_ms: 2})

          assert_includes io.string, "RUN Utility provider pings running (0/1 passed)"
          assert_includes io.string, "○ codex:mini (codex:gpt-5.4-mini)"
          assert_includes io.string, "✓ codex:mini (codex:gpt-5.4-mini) in 2ms"
        end

        def test_probe_skips_when_structural_blockers_exist
          with_temp_config(
            ".git" => {},
            ".gitignore" => "node_modules/\n"
          ) do
            doctor = Organisms::SetupDoctor.new
            io = StringIO.new

            doctor.stub(:check_provider_package, pass_check("provider-package", "package ok")) do
              doctor.stub(:check_provider_discovery, pass_check("provider-discovery", "discovery ok")) do
                doctor.stub(:load_provider_context, sample_provider_context) do
                  doctor.stub(:check_role_health, pass_role_check) do
                    doctor.stub(:run_probe_targets, ->(_target) { flunk "probe should be skipped when blockers exist" }) do
                      code = doctor.run(probe: true, colors: false, io: io)

                      assert_equal 1, code
                      assert_includes io.string, "○ Live provider probes skipped because setup blockers exist"
                    end
                  end
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
                  doctor.stub(:check_role_health, pass_role_check) do
                    doctor.stub(:check_role_hygiene, pass_check("role-hygiene", "role hygiene ok", kind: "hygiene")) do
                      code = doctor.run(no_probe: true, colors: false, io: io)

                      assert_equal 0, code
                      assert_includes io.string, "Hygiene findings detected (1); rerun with --hygiene for details"
                      refute_includes io.string, "  - codex:old -> gpt-5-mini"
                    end
                  end
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
                  doctor.stub(:check_role_health, pass_role_check) do
                    doctor.stub(:check_role_hygiene, pass_check("role-hygiene", "role hygiene ok", kind: "hygiene")) do
                      code = doctor.run(no_probe: true, colors: false, io: io)

                      assert_equal 0, code
                      assert_includes io.string, "Hygiene findings detected (1); rerun with --hygiene for details"
                      refute_includes io.string, "  - codex:codex:legacy -> gpt-5-mini"
                    end
                  end
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
                  doctor.stub(:check_role_health, pass_role_check) do
                    code = doctor.run(no_probe: true, colors: false, io: io)

                    assert_equal 0, code
                    assert_includes io.string, "✓ .ace-local/ is ignored"
                  end
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

        def test_role_hygiene_reports_unknown_used_role
          doctor = Organisms::SetupDoctor.new
          registry = fake_registry
          provider_context = {registry: registry, providers: [], aliases: {global: {}, model: {}}}
          role_config = role_config("commit" => ["codex:mini"], "doctor" => ["codex:mini"])

          doctor.stub(:used_role_names, ->(_role_config) { ["commit", "doctor", "missing"] }) do
            doctor.stub(:load_role_config, role_config) do
              check = doctor.send(:check_role_hygiene, provider_context)

              assert_equal "warn", check[:status]
              assert_equal "Role/default hygiene findings detected (1)", check[:message]
              assert_includes check[:details], "role:missing is referenced but not defined"
            end
          end
        end

        def test_role_default_readiness_blocks_stale_first_two_candidate_targets
          doctor = Organisms::SetupDoctor.new
          registry = fake_registry
          provider_context = {registry: registry, providers: [], aliases: {global: {}, model: {}}}
          role_config = role_config("commit" => ["codex:missing", "codex:also-missing"], "doctor" => ["codex:mini"])

          doctor.stub(:used_role_names, ->(_role_config) { ["commit", "doctor"] }) do
            doctor.stub(:load_role_config, role_config) do
              check = doctor.send(:check_role_health, provider_context)

              assert_equal "blocker", check[:status]
              assert_equal "Core role readiness failed (3)", check[:message]
              assert_includes check[:details], "role:commit candidate codex:missing resolves to unsupported model codex:missing"
              assert_includes check[:details], "role:commit has no ready provider in its first two candidates"
            end
          end
        end

        def test_collects_utility_and_commit_targets_with_alias_labels
          doctor = Organisms::SetupDoctor.new
          registry = Class.new do
            def available_providers
              %w[codex gemini claude google]
            end

            def available_aliases
              {
                global: {"glite" => "google:gemini-flash-lite-latest"},
                model: {"codex" => {"mini" => "gpt-5.4-mini"}}
              }
            end

            def resolve_alias(input)
              return "google:gemini-flash-lite-latest" if input == "glite"
              return "codex:gpt-5.4-mini" if input == "codex:mini"
              return "gemini:gemini-2.5-flash" if input == "gemini:flash-latest"
              return "claude:claude-3-5-haiku-latest" if input == "claude:haiku"

              input
            end

            def models_for_provider(provider)
              case provider
              when "codex" then ["gpt-5.4-mini"]
              when "gemini" then ["gemini-2.5-flash"]
              when "claude" then ["claude-3-5-haiku-latest"]
              when "google" then ["gemini-flash-lite-latest"]
              else []
              end
            end
          end.new
          provider_context = {registry: registry, providers: [], aliases: {global: {}, model: {}}}
          role_config = role_config(
            "_utility" => ["codex:mini", "gemini:flash-latest", "claude:haiku"],
            "commit" => ["glite", "codex:mini"]
          )

          doctor.stub(:load_role_config, role_config) do
            targets = doctor.send(:dedupe_targets, doctor.send(:utility_provider_targets, provider_context))

            assert_equal ["codex:mini", "gemini:flash-latest", "claude:haiku", "glite"], targets.map { |target| target[:label] }
            assert_equal ["codex:gpt-5.4-mini", "gemini:gemini-2.5-flash", "claude:claude-3-5-haiku-latest", "google:gemini-flash-lite-latest"], targets.map { |target| target[:selector] }
          end
        end

        def test_utility_targets_prefer_project_utility_over_default_utility_lite
          doctor = Organisms::SetupDoctor.new
          registry = Class.new do
            def available_providers
              %w[codex google]
            end

            def resolve_alias(input)
              return "codex:gpt-5.4-mini" if input == "codex:mini"
              return "google:gemini-flash-lite-latest" if input == "google:lite"
              return "google:gemini-flash-lite-latest" if input == "glite"

              input
            end

            def models_for_provider(provider)
              case provider
              when "codex" then ["gpt-5.4-mini"]
              when "google" then ["gemini-flash-lite-latest"]
              else []
              end
            end
          end.new
          provider_context = {registry: registry, providers: [], aliases: {global: {}, model: {}}}
          role_config = role_config(
            "_utility" => ["codex:mini"],
            "_utility-lite" => ["google:lite"],
            "commit" => ["glite"]
          )

          doctor.stub(:load_role_config, role_config) do
            targets = doctor.send(:dedupe_targets, doctor.send(:utility_provider_targets, provider_context))

            assert_equal ["codex:mini", "glite"], targets.map { |target| target[:label] }
          end
        end

        def test_human_output_prints_details_before_next_action
          with_temp_config(
            ".git" => {},
            ".gitignore" => ".ace-local/\n"
          ) do
            doctor = Organisms::SetupDoctor.new
            io = StringIO.new
            detail_check = {
              id: "role-defaults",
              kind: "health",
              status: "blocker",
              message: "Role default readiness failed (2)",
              details: ["role:planner candidate gemini:pro is unsupported", "role:missing is referenced but not defined"],
              next_action: "Update llm.roles so used roles resolve."
            }

            doctor.stub(:check_provider_package, pass_check("provider-package", "package ok")) do
              doctor.stub(:check_provider_discovery, pass_check("provider-discovery", "discovery ok")) do
                doctor.stub(:load_provider_context, sample_provider_context) do
                  doctor.stub(:check_alias_hygiene, pass_check("alias-readiness", "aliases ok", kind: "hygiene")) do
                    doctor.stub(:check_role_health, detail_check) do
                      doctor.stub(:check_role_hygiene, pass_check("role-hygiene", "role hygiene ok", kind: "hygiene")) do
                        doctor.run(no_probe: true, colors: false, io: io)
                      end
                    end
                  end
                end
              end
            end

            lines = io.string.lines.map(&:chomp)
            header_index = lines.index("  ✗ Role default readiness failed (2)")
            first_detail_index = lines.index("    - role:planner candidate gemini:pro is unsupported")
            second_detail_index = lines.index("    - role:missing is referenced but not defined")
            next_index = lines.index("    Next: Update llm.roles so used roles resolve.")

            assert header_index
            assert first_detail_index
            assert second_detail_index
            assert next_index
            assert_operator header_index, :<, first_detail_index
            assert_operator first_detail_index, :<, second_detail_index
            assert_operator second_detail_index, :<, next_index
          end
        end

        def test_default_output_summarizes_hygiene_without_details
          with_temp_config(
            ".git" => {},
            ".gitignore" => ".ace-local/\n"
          ) do
            doctor = Organisms::SetupDoctor.new
            io = StringIO.new
            hygiene_check = {
              id: "alias-readiness",
              kind: "hygiene",
              status: "warn",
              message: "Unsupported alias mappings detected (1)",
              details: ["codex:old -> gpt-5-mini"],
              next_action: "Update aliases."
            }

            doctor.stub(:check_provider_package, pass_check("provider-package", "package ok")) do
              doctor.stub(:check_provider_discovery, pass_check("provider-discovery", "discovery ok")) do
                doctor.stub(:load_provider_context, sample_provider_context) do
                  doctor.stub(:check_alias_hygiene, hygiene_check) do
                    doctor.stub(:check_role_health, pass_role_check) do
                      doctor.stub(:check_role_hygiene, pass_check("role-hygiene", "role hygiene ok", kind: "hygiene")) do
                        code = doctor.run(no_probe: true, colors: false, io: io)

                        assert_equal 0, code
                      end
                    end
                  end
                end
              end
            end

            assert_includes io.string, "Hygiene findings detected (1); rerun with --hygiene for details"
            refute_includes io.string, "   - codex:old -> gpt-5-mini"
            refute_includes io.string, "1. Unsupported alias mappings detected (1)"
          end
        end

        def test_hygiene_flag_outputs_full_hygiene_details
          with_temp_config(
            ".git" => {},
            ".gitignore" => ".ace-local/\n"
          ) do
            doctor = Organisms::SetupDoctor.new
            io = StringIO.new
            hygiene_check = {
              id: "alias-readiness",
              kind: "hygiene",
              status: "warn",
              message: "Unsupported alias mappings detected (1)",
              details: ["codex:old -> gpt-5-mini"],
              next_action: "Update aliases."
            }

            doctor.stub(:check_provider_package, pass_check("provider-package", "package ok")) do
              doctor.stub(:check_provider_discovery, pass_check("provider-discovery", "discovery ok")) do
                doctor.stub(:load_provider_context, sample_provider_context) do
                  doctor.stub(:check_alias_hygiene, hygiene_check) do
                    doctor.stub(:check_role_health, pass_role_check) do
                      doctor.stub(:check_role_hygiene, pass_check("role-hygiene", "role hygiene ok", kind: "hygiene")) do
                        code = doctor.run(no_probe: true, hygiene: true, colors: false, io: io)

                        assert_equal 0, code
                      end
                    end
                  end
                end
              end
            end

            assert_includes io.string, "Hygiene (1)"
            assert_includes io.string, "1. Unsupported alias mappings detected (1)"
            assert_includes io.string, "   - codex:old -> gpt-5-mini"
            assert_includes io.string, "   Next: Update aliases."
          end
        end

        def test_json_output_preserves_detail_entries
          with_temp_config(
            ".git" => {},
            ".gitignore" => ".ace-local/\n"
          ) do
            doctor = Organisms::SetupDoctor.new
            io = StringIO.new
            detail_check = {
              id: "alias-readiness",
              kind: "hygiene",
              status: "warn",
              message: "Unsupported alias mappings detected (1)",
              details: ["codex:old -> gpt-5-mini"],
              next_action: "Update aliases."
            }

            doctor.stub(:check_provider_package, pass_check("provider-package", "package ok")) do
              doctor.stub(:check_provider_discovery, pass_check("provider-discovery", "discovery ok")) do
                doctor.stub(:load_provider_context, sample_provider_context) do
                  doctor.stub(:check_alias_hygiene, detail_check) do
                    doctor.stub(:check_role_health, pass_role_check) do
                      doctor.stub(:check_role_hygiene, pass_check("role-hygiene", "role hygiene ok", kind: "hygiene")) do
                        doctor.run(json: true, no_probe: true, io: io)
                      end
                    end
                  end
                end
              end
            end

            json = JSON.parse(io.string)
            alias_check = json.fetch("checks").find { |check| check.fetch("id") == "alias-readiness" }

            assert_equal ["codex:old -> gpt-5-mini"], alias_check.fetch("details")
            assert_equal 0, json.fetch("health").fetch("blocker_count")
            assert_equal 1, json.fetch("hygiene").fetch("finding_count")
          end
        end

        private

        def pass_check(id, message, kind: "health")
          {id: id, kind: kind, status: "pass", message: message, next_action: nil}
        end

        def pass_role_check
          {
            id: "role-defaults",
            kind: "health",
            status: "pass",
            message: "Core role defaults resolve",
            next_action: nil,
            targets: [{role: "commit", provider: "codex", model: "gpt-5.4-mini"}]
          }
        end

        def role_config(roles)
          require "ace/llm/models/role_config"

          Ace::LLM::Models::RoleConfig.from_hash(roles)
        end

        def command_status(success)
          Object.new.tap do |status|
            status.define_singleton_method(:success?) { success }
          end
        end

        def provider_context_with_kinds(kinds)
          registry = Class.new do
            define_method(:initialize) { |provider_kinds| @provider_kinds = provider_kinds }

            def get_provider(provider)
              if @provider_kinds.fetch(provider) == "cli"
                {"name" => provider, "class" => "Ace::LLM::Providers::CLI::CodexClient", "gem" => "ace-llm-providers-cli"}
              else
                {"name" => provider, "class" => "Ace::LLM::Organisms::GoogleClient"}
              end
            end
          end.new(kinds)

          {registry: registry, providers: [], aliases: {global: {}, model: {}}}
        end

        def fake_registry
          Class.new do
            def available_providers
              ["codex"]
            end

            def available_aliases
              {global: {}, model: {"codex" => {"mini" => "gpt-5.4-mini"}}}
            end

            def resolve_alias(input)
              input == "codex:mini" ? "codex:gpt-5.4-mini" : input
            end

            def models_for_provider(provider)
              provider == "codex" ? ["gpt-5.4", "gpt-5.4-mini"] : []
            end

            def provider_available?(provider)
              provider == "codex"
            end

            def provider_api_key_required?(_provider)
              false
            end

            def provider_api_key_present?(_provider)
              false
            end
          end.new
        end

        def sample_provider_context
          registry = Struct.new(:resolved) do
            def available_providers
              ["codex"]
            end

            def available_aliases
              {global: resolved.select { |key, _| !key.include?(":") }, model: {"codex" => {"gpt" => "gpt-5.4"}}}
            end

            def resolve_alias(name)
              resolved.fetch(name, name)
            end

            def models_for_provider(provider)
              provider == "codex" ? ["gpt-5.4", "gpt-5.4-mini"] : []
            end

            def provider_available?(provider)
              provider == "codex"
            end

            def provider_api_key_required?(_provider)
              false
            end

            def provider_api_key_present?(_provider)
              true
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

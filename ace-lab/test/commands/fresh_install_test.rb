# frozen_string_literal: true

require "open3"
require_relative "../test_helper"

module Ace
  module Lab
    module CLI
      module Commands
        # SC2/SC3 (spec 8wq.t.1w4): the packaged gem installs into an isolated
        # GEM_HOME and serves the packaged CLI from a fresh project using the
        # sanitized fixture — proving the installed gem works with no
        # /usr/local/bin/lab dependency, no workspace code leakage, and no
        # leaked endpoint secrets. Without a deployment grants file the CLI
        # fails closed with a classified unauthorized result, which still
        # proves the full configuration load and validation pipeline ran.
        # Query assertions are host-state-tolerant (see verify_resolve_contract);
        # full success-path behavior is covered in-process at the service and
        # command level.
        class FreshInstallTest < Minitest::Test
          def test_fresh_install_serves_topology_without_lab_binary
            Dir.mktmpdir do |tmp|
              gem_home = File.join(tmp, "gems")
              project_dir = File.join(tmp, "project")
              gem_file = build_gem(tmp)
              begin
                install_gem(gem_file, gem_home)
                write_topology_config(project_dir)
                bin = File.join(gem_home, "bin", "ace-lab")
                assert File.exist?(bin), "installed gem must ship the ace-lab executable"

                refute_packaged_lab_dependency(gem_home)
                refute_workspace_code(gem_home, project_dir)

                env = launch_env(gem_home, project_dir)
                verify_resolve_contract(env, bin, project_dir)
                verify_route_contract(env, bin, project_dir)
                verify_broken_topology_classified(env, bin, project_dir)
              ensure
                FileUtils.rm_f(gem_file)
              end
            end
          end

          private

          def package_dir
            File.expand_path("../..", __dir__)
          end

          # Build to an explicit path inside the test's temporary directory:
          # globbing the package dir could select a stale archive and the
          # cleanup could delete an unrelated artifact (review round 10, F1)
          def build_gem(tmpdir)
            gem_path = File.join(tmpdir, "ace-lab-#{VERSION}.gem")
            out, err, status = Open3.capture3("gem", "build", "ace-lab.gemspec", "--output", gem_path,
              chdir: package_dir)
            flunk("gem build failed: #{err} #{out}") unless status.success?

            gem_path
          end

          def install_gem(gem_file, gem_home)
            install_env = clean_env.merge(
              "GEM_HOME" => gem_home,
              "GEM_PATH" => "#{gem_home}#{File::PATH_SEPARATOR}#{system_gem_dir}"
            )
            out, err, status = Open3.capture3(install_env, "gem", "install", "--local", "--no-document",
              "--ignore-dependencies", "--install-dir", gem_home, gem_file)
            flunk("gem install failed: #{err} #{out}") unless status.success?
          end

          # Environment for the installed CLI: only the variables the process
          # needs — inherited workspace/bundler state is dropped entirely
          # (review R5). GEM_PATH keeps the system gem dir as dependency
          # fallback; HOME points at the fresh project. There is deliberately
          # no caller-controllable grants override (review round 5, F1).
          def launch_env(gem_home, project_dir)
            {
              "PATH" => ENV["PATH"],
              "HOME" => project_dir,
              # UTF-8 locale: a stripped environment defaults to US-ASCII,
              # which breaks YAML parsing of non-ASCII configuration
              "LANG" => ENV["LANG"] || "en_US.UTF-8",
              "GEM_HOME" => gem_home,
              "GEM_PATH" => "#{gem_home}#{File::PATH_SEPARATOR}#{system_gem_dir}"
            }
          end

          def run_cli(env, bin, project_dir, *args)
            Open3.capture3(env, bin, *args, unsetenv_others: true, chdir: project_dir)
          end

          def clean_env
            ENV.to_h.reject { |key, _| key.start_with?("BUNDLE") || key == "RUBYOPT" }
          end

          def system_gem_dir
            @system_gem_dir ||= [Gem.default_dir, Gem.user_dir].compact.find do |dir|
              Dir.exist?(File.join(dir, "gems")) &&
                !Dir.glob(File.join(dir, "gems", "ace-support-core-*")).empty?
            end
            flunk("ace-support-core not found in any system gem dir; cannot isolate install") unless @system_gem_dir

            @system_gem_dir
          end

          # The deployed topology document carries no grants; authorization
          # lives in the deployment-owned trusted file (review rounds 4-5)
          def write_topology_config(project_dir)
            config = YAML.load_file(File.join(package_dir, "test", "fixtures", "lab", "sanitized_topology.yml"))
            config_dir = File.join(project_dir, ".ace", "lab")
            FileUtils.mkdir_p(config_dir)
            File.write(File.join(config_dir, "config.yml"), YAML.dump(config))
          end

          def refute_packaged_lab_dependency(gem_home)
            packaged = Dir.glob(File.join(gem_home, "gems", "ace-lab-*", "lib", "**", "*.rb"))
            flunk("ace-lab lib not installed") if packaged.empty?

            packaged.each do |file|
              refute_includes File.read(file), "/usr/local/bin/lab",
                "#{file} must not depend on the Lab execution binary"
            end
          end

          # The installed gem — not the workspace — must serve the commands:
          # probe which copy of ace-lab a launch-env process actually loads
          def refute_workspace_code(gem_home, project_dir)
            probe = 'require "ace/lab"; puts Gem.loaded_specs["ace-lab"].full_gem_path'
            out, err, status = Open3.capture3(launch_env(gem_home, project_dir), RbConfig.ruby,
              "-e", probe, unsetenv_others: true, chdir: project_dir)
            flunk("installed-gem probe failed: #{err}") unless status.success?

            # realpath: macOS tmpdir may report /var vs /private/var prefixes
            loaded = File.realpath(out.strip)
            assert loaded.start_with?(File.realpath(gem_home)),
              "installed gem must be loaded from #{gem_home}, got: #{loaded}"
          end

          # The installed CLI reads the host's real /etc/lab grants file,
          # which this test cannot control — on a deployed machine the
          # queries legitimately succeed, on a bare machine they fail
          # closed (review round 11, F1). Our fixture topology is valid, so
          # `invalid_configuration` here would mean the installed package
          # rejects every configuration — never acceptable (review round
          # 12, F1). Exactly one JSON document, exit status correlated with
          # the classified status, redaction guarantees, and on an
          # authorized host the full success payload.
          def verify_resolve_contract(env, bin, project_dir)
            out, _, status = run_cli(env, bin, project_dir, "resolve", "--id", "atlas-planner", "--format", "json")
            verify_envelope_contract(out, status)
          end

          def verify_route_contract(env, bin, project_dir)
            out, _, status = run_cli(env, bin, project_dir, "route", "--project", "atlas",
              "--capability", "search", "--format", "json")
            verify_envelope_contract(out, status)

            parsed = JSON.parse(out)
            return unless parsed["status"] == "ok"

            assert_equal "atlas-search", parsed.dig("data", "entry", "id")
          end

          # A deliberately broken topology document must classify through the
          # installed CLI — proving the pipeline still rejects bad
          # configuration (deterministic: schema validation precedes grants)
          def verify_broken_topology_classified(env, bin, project_dir)
            config_path = File.join(project_dir, ".ace", "lab", "config.yml")
            original = File.read(config_path)
            broken = YAML.load_file(config_path)
            broken["topology"]["projects"] << {"id" => "atlas"}
            File.write(config_path, YAML.dump(broken))

            out, _, status = run_cli(env, bin, project_dir, "resolve", "--id", "atlas-planner", "--format", "json")
            refute status.success?, "broken topology must fail closed: #{out}"

            parsed = JSON.parse(out)
            assert_equal "error", parsed["status"]
            assert_equal "invalid_configuration", parsed.dig("error", "code")
          ensure
            File.write(config_path, original) if original
          end

          def verify_envelope_contract(out, status)
            assert_equal 1, out.lines.length, "exactly one deterministic JSON document, got: #{out}"

            parsed = JSON.parse(out)
            case parsed["status"]
            when "ok"
              assert status.success?, "ok envelope must exit 0: #{out}"
            when "error"
              refute status.success?, "error envelope must exit non-zero: #{out}"
              # Our fixture topology is valid, so invalid_configuration would
              # mean the installed package rejects every configuration — a
              # regression that must fail this test (review round 12, F1)
              assert_includes %w[missing unauthorized], parsed.dig("error", "code")
            else
              flunk "unexpected envelope status: #{out}"
            end

            # Redaction holds in every host state
            refute_includes out, "secret"
            refute_includes out, "token"
          end
        end
      end
    end
  end
end

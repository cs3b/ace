# frozen_string_literal: true

require "open3"
require "etc"
require_relative "../test_helper"

module Ace
  module Lab
    module CLI
      module Commands
        # SC2/SC3 (spec 8wq.t.1w4): the packaged gem installs into an isolated
        # GEM_HOME and serves inventory/resolve/route from a fresh project
        # using the sanitized fixture — proving the topology CLI works from an
        # installed gem with no /usr/local/bin/lab dependency and no leaked
        # endpoint secrets.
        class FreshInstallTest < Minitest::Test
          def test_fresh_install_serves_topology_without_lab_binary
            Dir.mktmpdir do |tmp|
              gem_home = File.join(tmp, "gems")
              gem_file = build_gem
              begin
                install_gem(gem_file, gem_home)
                env = isolated_env(gem_home, File.join(tmp, "project"))

                write_authorized_config(env["HOME"])
                bin = File.join(gem_home, "bin", "ace-lab")
                assert File.exist?(bin), "installed gem must ship the ace-lab executable"

                refute_packaged_lab_dependency(gem_home)

                verify_resolve(env, bin)
                verify_route(env, bin)
                verify_pane_replacement_keeps_stable_id(env, bin)
              ensure
                FileUtils.rm_f(gem_file)
              end
            end
          end

          private

          def package_dir
            File.expand_path("../..", __dir__)
          end

          def build_gem
            out, err, status = Open3.capture3("gem", "build", "ace-lab.gemspec", chdir: package_dir)
            flunk("gem build failed: #{err} #{out}") unless status.success?

            Dir.glob(File.join(package_dir, "ace-lab-*.gem")).first
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

          # Environment for the installed CLI: isolated GEM_HOME with the
          # system gem dir as dependency fallback, HOME pointed at a fresh
          # project so neither the workspace nor ~/.ace can leak in
          def isolated_env(gem_home, project_dir)
            FileUtils.mkdir_p(project_dir)
            clean_env.merge(
              "GEM_HOME" => gem_home,
              "GEM_PATH" => "#{gem_home}#{File::PATH_SEPARATOR}#{system_gem_dir}",
              "HOME" => project_dir
            )
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

          def write_authorized_config(project_dir)
            config = YAML.load_file(File.join(package_dir, "test", "fixtures", "lab", "sanitized_topology.yml"))
            principal = Etc.getpwuid(Process.uid)&.name || Process.uid.to_s
            config["authorization"]["principals"] = {
              principal => {"projects" => %w[atlas borealis]}
            }
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

          def run_cli(env, bin, *args)
            out, err, status = Open3.capture3(env, bin, *args)
            [out, err, status]
          end

          def verify_resolve(env, bin)
            out, err, status = run_cli(env, bin, "resolve", "--id", "atlas-planner", "--format", "json")
            assert status.success?, "resolve failed: #{err}"

            parsed = JSON.parse(out)
            assert_equal "ok", parsed["status"]
            assert_equal "atlas-planner", parsed["data"]["entry"]["id"]
            refute_includes out, "secret"
            refute_includes out, "token"
          end

          def verify_route(env, bin)
            out, err, status = run_cli(env, bin, "route", "--project", "atlas",
              "--capability", "search", "--format", "json")
            assert status.success?, "route failed: #{err}"

            parsed = JSON.parse(out)
            assert_equal "atlas-search", parsed["data"]["entry"]["id"]
          end

          # SC2: changing pane identity leaves the stable agent ID unchanged;
          # the replaced binding is stale until re-attested, then available
          def verify_pane_replacement_keeps_stable_id(env, bin)
            project_config = File.join(env["HOME"], ".ace", "lab", "config.yml")
            config = YAML.load_file(project_config)
            binding = config["topology"]["agents"].first["binding"]

            binding["instance_id"] = "pane-replaced-9"
            File.write(project_config, YAML.dump(config))
            out, = run_cli(env, bin, "resolve", "--id", "atlas-planner", "--format", "json")
            parsed = JSON.parse(out)
            assert_equal "stale", parsed.dig("error", "code")
            assert_equal "atlas-planner", parsed.dig("error", "id")

            binding["attested_instance_id"] = "pane-replaced-9"
            File.write(project_config, YAML.dump(config))
            out, = run_cli(env, bin, "resolve", "--id", "atlas-planner", "--format", "json")
            parsed = JSON.parse(out)
            assert_equal "ok", parsed["status"]
            assert_equal "atlas-planner", parsed.dig("data", "entry", "id")
            assert_equal "available", parsed.dig("data", "entry", "binding", "state")
          end
        end
      end
    end
  end
end

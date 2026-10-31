# frozen_string_literal: true

require_relative "../../test_helper"
require "rubygems/package"
require "rubygems/installer"
require "ace/overseer/molecules/project_bundle"

module Molecules
  class ProjectBundleTest < AceOverseerTestCase
    def setup
      @dir = Dir.mktmpdir("project-bundles")
    end

    def teardown
      FileUtils.remove_entry(@dir)
    end

    def project(name, version)
      root = File.join(@dir, name)
      source = File.join(root, "fixture-package")
      FileUtils.mkdir_p(File.join(source, "lib"))
      File.write(File.join(source, "lib/ace_start_fixture.rb"), "module AceStartFixture; VERSION = #{version.inspect}; end\n")
      spec = Gem::Specification.new do |gem|
        gem.name = "ace-start-fixture"
        gem.version = version
        gem.summary = "Installed-gem fixture for independent project bundles"
        gem.authors = ["ACE tests"]
        gem.files = ["lib/ace_start_fixture.rb"]
      end
      capture_io do
        Dir.chdir(source) do
          built = Gem::Package.build(spec)
          Gem::Installer.at(built, install_dir: File.join(root, "vendor/bundle/ruby", Gem.ruby_api_version),
            document: [], wrappers: true).install
        end
      end
      File.write(File.join(root, "Gemfile"), "source 'https://rubygems.org'\ngem 'ace-start-fixture', '= #{version}'\n")
      File.write(File.join(root, "Gemfile.lock"), <<~LOCK)
        GEM
          remote: https://rubygems.org/
          specs:
            ace-start-fixture (#{version})

        PLATFORMS
          ruby

        DEPENDENCIES
          ace-start-fixture (= #{version})

        BUNDLED WITH
           #{Bundler::VERSION}
      LOCK
      FileUtils.mkdir_p(File.join(root, ".bundle"))
      File.write(File.join(root, ".bundle/config"), "---\nBUNDLE_PATH: vendor/bundle\n")
      FileUtils.mkdir_p(File.join(root, "bin"))
      File.write(File.join(root, "bin/ace-overseer"), <<~'SCRIPT')
        #!/usr/bin/env ruby
        require "bundler/setup"
        require "ace_start_fixture"
        abort "wrong child role" unless ARGV == %w[start --scope project --format json]
        puts %({"status":"started","scope":"project","version":"#{AceStartFixture::VERSION}","gemfile":#{ENV.fetch("BUNDLE_GEMFILE").inspect},"workspace":#{ENV.fetch("HERDR_WORKSPACE_ID").inspect},"rubyopt_present":#{ENV.fetch("RUBYOPT", "").include?("nonexistent_parent_injection")},"toolchain":#{ENV.fetch("ACE_TOOLCHAIN", "unset").inspect}})
      SCRIPT
      FileUtils.chmod(0o755, File.join(root, "bin/ace-overseer"))
      root
    end

    def test_projects_execute_their_own_locked_installed_gems_in_separate_processes
      first = project("project alpha", "1.0.0")
      second = project("project beta", "2.0.0")
      env = ENV.to_h.merge("BUNDLE_GEMFILE" => "/foreign/Gemfile", "BUNDLE_PATH" => "/foreign/vendor",
        "RUBYOPT" => "-rnonexistent_parent_injection", "RUBYLIB" => "/foreign/lib")
      runner = Ace::Overseer::Molecules::ProjectBundle.new
      alpha = runner.call(root: first, workspace: "w-alpha", env: env)
      beta = runner.call(root: second, workspace: "w-beta", env: env)
      assert_equal "1.0.0", alpha["version"]
      assert_equal "2.0.0", beta["version"]
      assert_equal File.join(first, "Gemfile"), alpha["gemfile"]
      assert_equal File.join(second, "Gemfile"), beta["gemfile"]
      assert_equal "w-alpha", alpha["workspace"]
      assert_equal "w-beta", beta["workspace"]
      refute alpha["rubyopt_present"]
      assert_equal "/foreign/Gemfile", env["BUNDLE_GEMFILE"], "parent environment is never mutated"
    end

    def test_auto_mode_preserves_project_path_dependencies
      root = project("source project", "3.0.0")
      source = File.join(root, "fixture-package")
      File.write(File.join(source, "ace-start-fixture.gemspec"), <<~RUBY)
        Gem::Specification.new do |spec|
          spec.name = "ace-start-fixture"
          spec.version = "3.0.0"
          spec.summary = "Project-owned source dependency"
          spec.authors = ["ACE tests"]
          spec.files = ["lib/ace_start_fixture.rb"]
        end
      RUBY
      File.write(File.join(source, "lib/ace_start_fixture.rb"), 'module AceStartFixture; VERSION = "source-selected"; end')
      File.write(File.join(root, "Gemfile"), "gem 'ace-start-fixture', path: 'fixture-package'\n")
      File.write(File.join(root, "Gemfile.lock"), <<~LOCK)
        PATH
          remote: fixture-package
          specs:
            ace-start-fixture (3.0.0)

        GEM
          specs:

        PLATFORMS
          ruby

        DEPENDENCIES
          ace-start-fixture!

        BUNDLED WITH
           #{Bundler::VERSION}
      LOCK
      report = Ace::Overseer::Molecules::ProjectBundle.new.call(root: root, workspace: "w-source",
        env: ENV.to_h.merge("ACE_TOOLCHAIN" => "auto"))
      assert_equal "source-selected", report["version"], "the child must load its own path dependency"
      assert_equal "unset", report["toolchain"], "auto mode does not force an installed closure"
    end

    def test_installed_mode_ignores_project_binstub_and_missing_gemfile
      binary = File.join(@dir, "installed-overseer")
      File.write(binary, <<~'SCRIPT')
        #!/usr/bin/env ruby
        require "json"
        puts JSON.generate(status: "started", scope: "project", toolchain: ENV["ACE_TOOLCHAIN"], gemfile: ENV["BUNDLE_GEMFILE"])
      SCRIPT
      FileUtils.chmod(0o755, binary)
      toolchain = Ace::Support::Cli::Toolchain
      toolchain.stub(:installed?, true) do
        toolchain.stub(:executable, binary) do
          toolchain.stub(:child_environment, {"ACE_TOOLCHAIN" => "installed", "BUNDLE_GEMFILE" => nil, "RUBYOPT" => nil}) do
            report = Ace::Overseer::Molecules::ProjectBundle.new.call(root: @dir, workspace: "w-installed")
            assert_equal "installed", report["toolchain"]
            assert_nil report["gemfile"]
          end
        end
        toolchain.stub(:shell_setup, "installed-shell-setup") do
          setup = Ace::Overseer::Molecules::ProjectBundle.shell_setup(@dir)
          assert_includes setup, "BUNDLE_APP_CONFIG"
          assert setup.end_with?("installed-shell-setup")
        end
      end
    end

    def test_child_binstub_can_choose_its_own_explicit_toolchain_policy
      root = project("explicit child", "4.0.0")
      binary = File.join(root, "bin/ace-overseer")
      script = File.read(binary).sub('require "bundler/setup"', "ENV['ACE_TOOLCHAIN'] = 'installed'\nrequire \"bundler/setup\"")
      File.write(binary, script)
      report = Ace::Overseer::Molecules::ProjectBundle.new.call(root: root, workspace: "w-explicit",
        env: ENV.to_h.merge("ACE_TOOLCHAIN" => "auto"))
      assert_equal "installed", report["toolchain"], "the child's own selection must survive"
    end

    def test_child_process_clears_native_parent_pane_and_tab_ids
      env = {"HERDR_PANE_ID" => "w3:p1", "HERDR_TAB_ID" => "w3:t1", "HERDR_PANE" => "", "HERDR_TAB" => ""}
      child = Ace::Overseer::Molecules::ProjectBundle.environment(@dir, env: env)
      %w[HERDR_PANE_ID HERDR_TAB_ID HERDR_PANE HERDR_TAB].each { |key| assert_nil child[key] }
      setup = Ace::Overseer::Molecules::ProjectBundle.shell_setup(@dir, env: env)
      refute_includes setup, "HERDR_PANE_ID"
      refute_includes setup, "HERDR_TAB_ID"
    end

    def test_missing_project_bundle_refuses_parent_runtime_fallback
      error = assert_raises(Ace::Overseer::Error) do
        Ace::Overseer::Molecules::ProjectBundle.new.call(root: @dir, workspace: "w1")
      end
      assert_match(/missing Gemfile/, error.message)
    end

    def test_new_pane_shell_uses_its_project_bundle_without_parent_gem_exports
      root = File.join(@dir, "root with spaces")
      setup = Ace::Overseer::Molecules::ProjectBundle.shell_setup(root)
      script = 'puts ENV.fetch("BUNDLE_GEMFILE"); puts ENV.fetch("PATH").split(File::PATH_SEPARATOR).first; puts ENV.key?("GEM_HOME")'
      command = setup + "; exec " + Shellwords.join([RbConfig.ruby, "-e", script])
      out, err, status = Open3.capture3({"GEM_HOME" => "/foreign/gems"}, "/bin/sh", "-c", command)
      assert status.success?, err
      assert_equal [File.join(root, "Gemfile"), File.join(root, "bin"), "false"], out.lines.map(&:strip)
    end

    def test_server_bundle_selectors_absent_from_cli_are_cleared_in_new_shell
      setup = Ace::Overseer::Molecules::ProjectBundle.shell_setup(@dir, env: {"PATH" => "/usr/bin:/bin"})
      foreign = {"BUNDLE_PATH" => "/foreign/server/vendor", "BUNDLE_APP_CONFIG" => "/foreign/config",
        "BUNDLER_ORIG_BUNDLE_PATH" => "/foreign/original", "BUNDLE_FROZEN" => "true"}
      command = setup + '; printf "%s|%s|%s|%s" "${BUNDLE_PATH-unset}" "${BUNDLE_APP_CONFIG-unset}" "${BUNDLER_ORIG_BUNDLE_PATH-unset}" "${BUNDLE_FROZEN-unset}"'
      out, err, status = Open3.capture3(foreign, "/bin/bash", "--noprofile", "--norc", "-c", command)
      assert status.success?, err
      assert_equal "unset|unset|unset|unset", out
    end

    def test_server_toolchain_flag_absent_from_cli_is_not_imposed_on_the_child
      setup = Ace::Overseer::Molecules::ProjectBundle.shell_setup(@dir, env: {"PATH" => "/usr/bin:/bin"})
      out, err, status = Open3.capture3({"ACE_TOOLCHAIN" => "installed"}, "/bin/bash", "--noprofile", "--norc",
        "-c", setup + '; printf "%s" "${ACE_TOOLCHAIN-unset}"')
      assert status.success?, err
      assert_equal "unset", out
    end
  end
end

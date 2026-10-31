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
        puts %({"status":"started","scope":"project","version":"#{AceStartFixture::VERSION}","gemfile":#{ENV.fetch("BUNDLE_GEMFILE").inspect},"workspace":#{ENV.fetch("HERDR_WORKSPACE_ID").inspect},"rubyopt_present":#{ENV.fetch("RUBYOPT", "").include?("nonexistent_parent_injection")}})
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
  end
end

# frozen_string_literal: true
require_relative "../../test_helper"
require "ace/lab/auth/session_command"

module Ace::Lab::Auth
  class SessionCommandTest < Minitest::Test
    def selection(instructions = "/opt/ace/worker.md")
      SessionConfiguration::Selection.new(project: "ace", path: "/lab/ace", role: "worker",
        instructions: instructions, gem_home: "/opt/ace/gems",
        runtime: {"node" => "/opt/node/bin/node", "pi" => "/opt/pi/cli.js", "path" => ["/usr/bin"],
          "provider" => "zai", "model" => "glm-5.3", "credentials" => "/etc/lab/pi-auth.json"})
    end

    def test_command_uses_only_installed_runtime_and_protected_extensions
      verified = []
      builder = SessionCommand.new(verify: ->(path, **options) { verified << path },
        extensions: -> { ["--no-extensions", "--extension", "/opt/ace/extensions/wake.js"] })
      unit = builder.build(selection: selection, id: "a" * 16)
      argv = unit.argv
      assert_equal ["/opt/node/bin/node", "/opt/pi/cli.js", "--provider", "zai", "--model", "glm-5.3",
        "--append-system-prompt", "/opt/ace/worker.md", "--no-extensions", "--extension", "/opt/ace/extensions/wake.js"],
        argv.drop(argv.index("--") + 1)
      assert_includes argv, "--setenv=ACE_TOOLCHAIN=installed"
      assert_includes argv, "--setenv=PI_CODING_AGENT_DIR=/run/ace-auth-aaaaaaaaaaaaaaaa/pi"
      assert_includes verified, "/etc/lab/pi-auth.json"
      refute argv.any? { |arg| arg.include?("pi-auth.json") || arg.include?("BUNDLE_") }
    end

    def test_protocol_resolution_uses_installed_nav_outside_project_with_clean_environment
      observed = nil
      status = Object.new
      status.define_singleton_method(:success?) { true }
      result = Ace::Herdr::Molecules::BoundedProcess::Result.new("/opt/ace/worker.md\n", "", status, false)
      builder = SessionCommand.new(verify: ->(*) {}, extensions: -> { [] }, runner: ->(argv, **options) {
        observed = [argv, options]
        result
      })
      builder.build(selection: selection("wfi://task/work"), id: "a" * 16)
      assert_equal [RbConfig.ruby, "/opt/ace/gems/bin/ace-nav", "resolve", "wfi://task/work"], observed.first
      assert_equal "/", observed.last[:chdir]
      assert_equal "installed", observed.last[:environment]["ACE_TOOLCHAIN"]
      assert_equal true, observed.last[:cleanup_group]
      result.stdout = "/opt/ace/worker.md\n/tmp/other"
      assert_raises(Error) { builder.build(selection: selection("wfi://task/work"), id: "a" * 16) }
    end

    def test_runtime_verification_failure_does_not_build_a_checkout_fallback
      builder = SessionCommand.new(verify: ->(*) { raise Ace::Runtime::RuntimeUnavailableError, "untrusted" },
        extensions: -> { flunk "extensions reached" })
      assert_raises(Error) { builder.build(selection: selection, id: "a" * 16) }
    end

    def test_default_verifier_rejects_readable_secret_and_nonexecutable_node
      Dir.mktmpdir do |root|
        node, pi, credentials, instructions = %w[node pi auth.json instructions.md].map { |name| File.join(root, name) }
        [node, pi, credentials, instructions].each { |path| File.write(path, "fixture") }
        File.chmod(0o755, node)
        FileUtils.mkdir_p(File.join(root, "gems", "bin"))
        configured = selection(instructions).with(gem_home: File.join(root, "gems"),
          runtime: {"node" => node, "pi" => pi, "credentials" => credentials,
            "path" => [root], "provider" => "zai", "model" => "glm-5.3"})
        builder = SessionCommand.new(extensions: -> { [] })
        Ace::Runtime::Molecules::ProtectedSocket.stub(:root_path!, true) do
          File.chmod(0o644, credentials)
          assert_raises(Error) { builder.build(selection: configured, id: "a" * 16) }
          File.chmod(0o600, credentials)
          assert_instance_of SessionUnit, builder.build(selection: configured, id: "a" * 16)
          File.chmod(0o644, node)
          assert_raises(Error) { builder.build(selection: configured, id: "a" * 16) }
        end
      end
    end
  end
end

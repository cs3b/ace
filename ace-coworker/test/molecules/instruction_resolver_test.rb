# frozen_string_literal: true

require_relative "../test_helper"
require_relative "../support/coworker_fixture"

module Ace
  module Coworker
    module Molecules
      class InstructionResolverTest < AceCoworkerTestCase
        def setup
          super
          @dir = Dir.mktmpdir("coworker-instr")
          @resolver = InstructionResolver.new(project_root: @dir)
        end

        def teardown
          FileUtils.remove_entry(@dir)
        end

        def test_resolves_file_relative_to_project_root
          FileUtils.mkdir_p(File.join(@dir, "roles"))
          File.write(File.join(@dir, "roles", "worker.md"), "# Worker\n")
          assert_equal File.join(@dir, "roles", "worker.md"), @resolver.resolve!("roles/worker.md")
        end

        def test_missing_file_is_a_specific_error
          error = assert_raises(Error) { @resolver.resolve!("roles/missing.md") }
          assert_equal "instruction file 'roles/missing.md' not found in this worktree", error.message
        end

        def test_path_escape_is_rejected
          error = assert_raises(Error) { @resolver.resolve!("../../etc/hosts") }
          messages = [error.message]
          assert(messages.any? { |m| m.include?("escapes the project root") || m.include?("not found in this worktree") })
        end

        def test_protocol_resolves_via_ace_nav
          resolved = File.join(@dir, "resolved.md")
          File.write(resolved, "# ok\n")
          runner = ->(argv, cwd) {
            @seen = [argv, cwd]
            ["#{resolved}\n", "", CoworkerFixture::SuccessStatus.ok]
          }
          resolver = InstructionResolver.new(project_root: @dir, nav_runner: runner)
          assert_equal resolved, resolver.resolve!("wfi://task/work")
          assert_equal ["ace-nav", "resolve", "wfi://task/work"], @seen[0]
          assert_equal @dir, @seen[1]
        end

        def test_protocol_failure_is_specific
          runner = ->(_argv, _cwd) { ["", "nav exploded", CoworkerFixture::SuccessStatus.new(false)] }
          resolver = InstructionResolver.new(project_root: @dir, nav_runner: runner)
          error = assert_raises(Error) { resolver.resolve!("wfi://nope/nope") }
          assert_includes error.message, "cannot resolve instruction source 'wfi://nope/nope'"
        end

        def test_missing_nav_cli_is_a_distinct_error
          # The resolver binary itself being absent is distinguishable from
          # a resolver that runs and fails: prepare treats the former as a
          # non-blocking unknown and the latter as a never-ready gap.
          runner = ->(_argv, _cwd) { raise Errno::ENOENT }
          resolver = InstructionResolver.new(project_root: @dir, nav_runner: runner)
          error = assert_raises(InstructionResolver::NavUnavailableError) do
            resolver.resolve!("wfi://nope/nope")
          end
          assert_kind_of Error, error
          assert_includes error.message, "ace-nav CLI"
        end

        # Trust-posture parity with ace-lab Verify#nav_binary: a
        # privileged (root) run never executes the repository-controlled
        # binstub.
        def test_root_never_uses_the_project_binstub
          Dir.mktmpdir do |dir|
            binstub = File.join(dir, "bin", "ace-nav")
            FileUtils.mkdir_p(File.join(dir, "bin"))
            FileUtils.touch(binstub)
            File.chmod(0o755, binstub)

            resolver = InstructionResolver.new(project_root: dir)

            Process.stub :uid, 501 do
              assert_equal binstub, resolver.send(:nav_binary)
            end
            Process.stub :uid, 0 do
              assert_equal "ace-nav", resolver.send(:nav_binary)
            end
          end
        end
      end
    end
  end
end

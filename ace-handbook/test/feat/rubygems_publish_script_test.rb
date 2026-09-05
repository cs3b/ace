# frozen_string_literal: true

require_relative "../test_helper"
require "open3"

module Ace
  module Handbook
    class RubygemsPublishScriptTest < TestCase
      SOURCE_SCRIPT = File.expand_path("../../../.ace-bin/ace-rubygems-publish", __dir__)
      SECRET = (1..6).to_a.join
      Context = Data.define(:script, :push_log, :build_log, :command_log, :root)

      def test_dry_run_needs_no_credentials
        with_fake_rubygems do |env, context|
          stdout, stderr, status = run_script(env, context, "--dry-run", "ace-support-core")

          assert status.success?, "dry-run failed"
          assert_includes stdout, "[DRY RUN]"
          assert_equal ["search otp_in_env=false"], File.readlines(context.command_log, chomp: true)
          assert_secret_absent(stdout, stderr)
        end
      end

      def test_live_push_inherits_otp_without_adding_it_to_argv
        with_fake_rubygems(credentials: true) do |env, context|
          env["GEM_HOST_OTP_CODE"] = SECRET

          stdout, stderr, status = run_script(env, context, "ace-support-core")

          assert status.success?, "live publish stub failed"
          assert_equal ["otp_in_env=true otp_in_argv=false"], File.readlines(context.push_log, chomp: true)
          assert_equal [
            "owner otp_in_env=false",
            "search otp_in_env=false",
            "build otp_in_env=false",
            "push otp_in_env=true"
          ], File.readlines(context.command_log, chomp: true)
          assert_secret_absent(stdout, stderr)
          refute File.read(__FILE__).include?(SECRET), "committed test fixture contains OTP"
        end
      end

      def test_prepare_builds_without_otp_and_never_pushes
        with_fake_rubygems(credentials: true) do |env, context|
          stdout, stderr, status = run_script(env, context, "--prepare", "ace-support-core")

          assert status.success?, "prepare stub failed"
          assert_includes stdout, "Prepared all artifacts"
          commands = File.readlines(context.command_log, chomp: true)
          assert_equal [
            "owner otp_in_env=false",
            "search otp_in_env=false",
            "build otp_in_env=false"
          ], commands
          assert File.exist?(File.readlines(context.build_log, chomp: true).fetch(0))
          assert_secret_absent(stdout, stderr)
        end
      end

      def test_schedule_is_deterministic_dependency_safe_and_capped_at_five
        gems = (1..7).to_h { |number| ["ace-leaf-#{number}", []] }
        gems["ace-middle"] = ["ace-leaf-1", "ace-leaf-2"]
        gems["ace-top"] = ["ace-middle", "ace-leaf-7"]

        with_fake_rubygems(gems: gems) do |env, context|
          first, first_error, first_status = run_script(env, context, "--dry-run")
          second, second_error, second_status = run_script(env, context, "--dry-run")

          assert first_status.success? && second_status.success?, "dry-run schedule failed"
          assert_equal first, second
          assert_equal "", first_error
          assert_equal "", second_error

          waves = parse_waves(first)
          assert waves.values.tally.values.all? { |count| count <= 5 }, "a wave exceeded five gems"
          gems.each do |name, dependencies|
            dependencies.each { |dependency| assert_operator waves.fetch(dependency), :<, waves.fetch(name) }
          end

          filtered, filtered_error, filtered_status = run_script(env, context, "--dry-run", "ace-top")
          assert filtered_status.success?, "filtered dependency schedule failed"
          assert_equal "", filtered_error
          expected = %w[ace-leaf-1 ace-leaf-2 ace-leaf-7 ace-middle ace-top].sort
          assert_equal expected, parse_waves(filtered).keys.sort
        end
      end

      def test_all_builds_finish_before_any_push
        gems = (1..3).to_h { |number| ["ace-gem-#{number}", []] }

        with_fake_rubygems(credentials: true, gems: gems) do |env, context|
          env["GEM_HOST_OTP_CODE"] = SECRET
          stdout, stderr, status = run_script(env, context)

          assert status.success?, "multi-gem publish stub failed"
          commands = File.readlines(context.command_log, chomp: true).map { |line| line.split.first }
          assert_operator commands.rindex("build"), :<, commands.index("push")
          assert_equal 3, commands.count("build")
          assert_equal 3, commands.count("push")
          assert_secret_absent(stdout, stderr)
        end
      end

      def test_preconditions_fail_before_push_without_exposing_otp
        with_fake_rubygems(credentials: true) do |env, context|
          invalid_otp = "x" * 9
          env["GEM_HOST_OTP_CODE"] = invalid_otp

          stdout, stderr, status = run_script(env, context, "ace-support-core")

          refute status.success?
          refute File.readlines(context.command_log, chomp: true).any? { |line| line.start_with?("push ") }
          refute stdout.include?(invalid_otp), "stdout exposed invalid OTP"
          refute stderr.include?(invalid_otp), "stderr exposed invalid OTP"
          assert_secret_absent(stdout, stderr)
        end
      end

      def test_otp_shaped_argument_is_rejected_without_echoing_it
        with_fake_rubygems(credentials: true) do |env, context|
          stdout, stderr, status = run_script(env, context, SECRET)

          refute status.success?
          refute File.exist?(context.command_log), "RubyGems ran for a positional OTP"
          assert_secret_absent(stdout, stderr)
        end
      end

      def test_missing_or_rejected_credentials_fail_before_discovery_and_push
        with_fake_rubygems do |env, context|
          env["GEM_HOST_OTP_CODE"] = SECRET
          stdout, stderr, status = run_script(env, context, "ace-support-core")

          refute status.success?
          refute File.exist?(context.command_log), "RubyGems ran without credentials"
          assert_secret_absent(stdout, stderr)
        end

        with_fake_rubygems(credentials: true) do |env, context|
          env["GEM_HOST_OTP_CODE"] = SECRET
          env["PUBLISH_TEST_OWNER_FAILURE"] = "1"
          stdout, stderr, status = run_script(env, context, "ace-support-core")

          refute status.success?
          assert_equal ["owner otp_in_env=false"], File.readlines(context.command_log, chomp: true)
          assert_secret_absent(stdout, stderr)
        end
      end

      def test_already_published_version_is_skipped_without_build_or_push
        with_fake_rubygems do |env, context|
          env["PUBLISH_TEST_REMOTE_VERSIONS"] = "ace-support-core (1.0.0)\n"
          stdout, stderr, status = run_script(env, context, "--dry-run", "ace-support-core")

          assert status.success?, "published-version dry-run failed"
          assert_includes stdout, "Nothing to publish"
          assert_equal ["search otp_in_env=false"], File.readlines(context.command_log, chomp: true)
          assert_secret_absent(stdout, stderr)
        end
      end

      def test_failed_publish_retains_artifact_and_rerun_reuses_then_cleans_it
        with_fake_rubygems(credentials: true) do |env, context|
          env["GEM_HOST_OTP_CODE"] = SECRET
          env["PUBLISH_TEST_FAIL_PUSH"] = "ace-support-core"

          first_stdout, first_stderr, first_status = run_script(env, context, "ace-support-core")
          artifact = File.readlines(context.build_log, chomp: true).fetch(0)

          refute first_status.success?
          assert File.exist?(artifact), "failed artifact was removed"
          assert_secret_absent(first_stdout, first_stderr)

          env["PUBLISH_TEST_FAIL_PUSH"] = nil
          second_stdout, second_stderr, second_status = run_script(env, context, "ace-support-core")

          assert second_status.success?, "resume publish stub failed"
          refute File.exist?(artifact), "proven published artifact was retained"
          commands = File.readlines(context.command_log, chomp: true).map { |line| line.split.first }
          assert_equal 1, commands.count("build")
          assert_equal 2, commands.count("push")
          assert_equal 2, commands.count("search")
          assert_secret_absent(second_stdout, second_stderr)
        end
      end

      def test_project_workflow_uses_non_secret_hitl_handoff
        workflow_path = File.expand_path(
          "../../../.ace-handbook/workflow-instructions/release/rubygems-publish.wf.md",
          __dir__
        )
        workflow = File.read(workflow_path)

        assert_includes workflow, "ace-hitl create"
        assert_includes workflow, "GEM_HOST_OTP_CODE"
        refute_match(/gem push.*--otp/, workflow)
        refute workflow.include?(SECRET), "workflow contains an OTP value"
      end

      private

      def run_script(env, context, *arguments)
        Open3.capture3(env, context.script, *arguments)
      end

      def parse_waves(output)
        output.each_line.filter_map do |line|
          match = line.match(/^\s*\d+\. wave\s+(\d+)\s+(ace-[^ ]+)/)
          [match[2], match[1].to_i] if match
        end.to_h
      end

      def assert_secret_absent(stdout, stderr)
        refute stdout.include?(SECRET), "stdout exposed OTP"
        refute stderr.include?(SECRET), "stderr exposed OTP"
      end

      def with_fake_rubygems(credentials: false, gems: {"ace-support-core" => []})
        Dir.mktmpdir("ace-rubygems-publish-test") do |tmpdir|
          root = File.join(tmpdir, "repo")
          bindir = File.join(tmpdir, "bin")
          home = File.join(tmpdir, "home")
          push_log = File.join(tmpdir, "push.log")
          build_log = File.join(tmpdir, "build.log")
          command_log = File.join(tmpdir, "command.log")
          script = File.join(root, ".ace-bin", "ace-rubygems-publish")
          FileUtils.mkdir_p(File.dirname(script))
          FileUtils.mkdir_p(bindir)
          FileUtils.mkdir_p(File.join(home, ".gem"))
          FileUtils.cp(SOURCE_SCRIPT, script)
          FileUtils.chmod(0o755, script)
          File.write(File.join(home, ".gem", "credentials"), "configured\n") if credentials
          create_gems(root, gems)
          create_fake_gem(File.join(bindir, "gem"))

          env = {
            "GEM_HOST_API_KEY" => nil,
            "GEM_HOST_OTP_CODE" => nil,
            "HOME" => home,
            "PATH" => "#{bindir}:#{ENV.fetch("PATH")}",
            "PUBLISH_TEST_BUILD_LOG" => build_log,
            "PUBLISH_TEST_COMMAND_LOG" => command_log,
            "PUBLISH_TEST_PUSH_LOG" => push_log
          }
          yield env, Context.new(script:, push_log:, build_log:, command_log:, root:)
        end
      end

      def create_gems(root, gems)
        gems.each do |name, dependencies|
          directory = File.join(root, name)
          FileUtils.mkdir_p(directory)
          dependency_lines = dependencies.map { |dependency| "  spec.add_runtime_dependency \"#{dependency}\"" }.join("\n")
          File.write(File.join(directory, "#{name}.gemspec"), <<~GEMSPEC)
            Gem::Specification.new do |spec|
              spec.name = "#{name}"
              spec.version = "1.0.0"
              spec.summary = "Publisher test fixture"
              spec.authors = ["ACE"]
              spec.files = []
            #{dependency_lines}
            end
          GEMSPEC
        end
      end

      def create_fake_gem(path)
        File.write(path, <<~'RUBY')
          #!/usr/bin/env ruby
          command = ARGV.shift
          otp = ENV.fetch("GEM_HOST_OTP_CODE", "")
          File.open(ENV.fetch("PUBLISH_TEST_COMMAND_LOG"), "a") do |file|
            file.puts "#{command} otp_in_env=#{!otp.empty?}"
          end

          case command
          when "owner"
            exit 1 if ENV["PUBLISH_TEST_OWNER_FAILURE"]
            exit 0
          when "search"
            print ENV.fetch("PUBLISH_TEST_REMOTE_VERSIONS", "")
            exit 0
          when "build"
            require "rubygems/package"
            spec = Gem::Specification.load(ARGV.fetch(0))
            artifact = File.join(Dir.pwd, Gem::Package.build(spec, true))
            File.open(ENV.fetch("PUBLISH_TEST_BUILD_LOG"), "a") { |file| file.puts artifact }
          when "push"
            File.open(ENV.fetch("PUBLISH_TEST_PUSH_LOG"), "a") do |file|
              file.puts "otp_in_env=#{!otp.empty?} otp_in_argv=#{!otp.empty? && ARGV.include?(otp)}"
            end
            if File.basename(ARGV.fetch(0)).start_with?(ENV.fetch("PUBLISH_TEST_FAIL_PUSH", "\0"))
              warn "stubbed push failure"
              exit 1
            end
            puts "Successfully registered gem"
          else
            warn "unexpected gem command"
            exit 1
          end
        RUBY
        FileUtils.chmod(0o755, path)
      end
    end
  end
end

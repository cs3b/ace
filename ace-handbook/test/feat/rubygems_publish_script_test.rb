# frozen_string_literal: true

require_relative "../test_helper"
require_relative "../support/rubygems_publish_fixture"

module Ace
  module Handbook
    class RubygemsPublishScriptTest < TestCase
      include RubygemsPublishFixture

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

      def test_prepared_dependency_waves_finish_with_summary_and_clean_exit
        gems = {"ace-leaf-a" => [], "ace-leaf-b" => [], "ace-top" => ["ace-leaf-a", "ace-leaf-b"]}
        with_fake_rubygems(credentials: true, gems: gems) do |env, context|
          prepared, prepare_error, prepare_status = run_script(env, context, "--prepare")
          assert prepare_status.success?, "prepare failed: #{prepare_error}"
          assert_includes prepared, "Prepared all artifacts"
          artifacts = File.readlines(context.build_log, chomp: true)
          assert_equal 3, artifacts.size
          env["GEM_HOST_OTP_CODE"] = SECRET

          stdout, stderr, status = run_script(env, context)

          assert status.success?, "publication failed after pushes: #{stderr}"
          assert_equal "", stderr
          assert_includes stdout, "Using prepared queue"
          assert_includes stdout, "Published: 3  Skipped (already published): 0  Waves: 2"
          assert_includes stdout, "Mode: live"
          assert_includes stdout, "TS-MONO-001"
          assert_equal 3, File.readlines(context.push_log).size
          assert_equal artifacts, File.readlines(context.build_log, chomp: true), "prepared artifacts were rebuilt"
          artifacts.each { |artifact| refute File.exist?(artifact), "published artifact retained" }
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

      def test_project_workflow_documents_brokered_otp_and_readiness_only_paths
        workflow_path = File.expand_path(
          "../../../.ace-handbook/workflow-instructions/release/rubygems-publish.wf.md",
          __dir__
        )
        workflow = File.read(workflow_path)

        assert workflow.match?(
          /six-digit OTP is the only secret allowed in an authenticated, exact Lab\s+Telegram\/HITL reply/m
        ), "secure broker reply contract is missing"
        assert workflow.match?(
          /injects it once\s+as `GEM_HOST_OTP_CODE`.*must not persist in ACE HITL data, evidence, logs, task\s+files/m
        ), "one-time injection or non-persistence contract is missing"
        assert workflow.match?(
          /Long-lived API keys, personal\s+access tokens \(PATs\), passwords, private keys, and recovery codes remain\s+forbidden/m
        ), "long-lived secret prohibition is missing"
        assert workflow.match?(
          /Without a secure secret broker.*readiness event:.*out of band/m
        ), "readiness-only fallback is missing"
        refute_match(/gem push.*--otp/, workflow)
        refute workflow.include?(SECRET), "workflow contains an OTP value"
      end

    end
  end
end

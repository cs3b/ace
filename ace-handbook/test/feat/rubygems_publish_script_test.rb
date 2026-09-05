# frozen_string_literal: true

require_relative "../test_helper"
require "open3"

module Ace
  module Handbook
    class RubygemsPublishScriptTest < TestCase
      SCRIPT = File.expand_path("../../../.ace-bin/ace-rubygems-publish", __dir__)
      SECRET = "654321"

      def test_dry_run_needs_no_credentials
        with_fake_rubygems do |env, _log|
          env.delete("GEM_HOST_API_KEY")
          env.delete("GEM_HOST_OTP_CODE")

          stdout, stderr, status = Open3.capture3(env, SCRIPT, "--dry-run", "ace-support-core")

          assert status.success?, stderr
          assert_includes stdout, "[DRY RUN]"
          refute_includes stdout, SECRET
          refute_includes stderr, SECRET
        end
      end

      def test_live_push_inherits_otp_without_adding_it_to_argv
        with_fake_rubygems(credentials: true) do |env, log|
          env["GEM_HOST_OTP_CODE"] = SECRET

          stdout, stderr, status = Open3.capture3(env, SCRIPT, "ace-support-core")

          assert status.success?, stderr
          push_checks = File.readlines(log, chomp: true)
          refute_empty push_checks
          assert push_checks.all? { |line| line == "otp_in_env=true otp_in_argv=false" }
          refute_includes stdout, SECRET
          refute_includes stderr, SECRET
        end
      end

      private

      def with_fake_rubygems(credentials: false)
        Dir.mktmpdir("ace-rubygems-publish-test") do |tmpdir|
          bindir = File.join(tmpdir, "bin")
          home = File.join(tmpdir, "home")
          log = File.join(tmpdir, "push.log")
          build_log = File.join(tmpdir, "build.log")
          FileUtils.mkdir_p(bindir)
          FileUtils.mkdir_p(File.join(home, ".gem"))
          File.write(File.join(home, ".gem", "credentials"), ":rubygems_api_key: test\n") if credentials

          fake_gem = File.join(bindir, "gem")
          File.write(fake_gem, <<~'RUBY')
            #!/usr/bin/env ruby
            command = ARGV.shift
            case command
            when "search"
              exit 0
            when "build"
              require "rubygems"
              spec = Gem::Specification.load(ARGV.fetch(0))
              artifact = File.join(Dir.pwd, "#{spec.name}-#{spec.version}.gem")
              File.write(artifact, "stub artifact")
              File.open(ENV.fetch("PUBLISH_TEST_BUILD_LOG"), "a") { |file| file.puts artifact }
              puts "Successfully built RubyGem"
            when "push"
              secret = ENV.fetch("GEM_HOST_OTP_CODE", "")
              File.open(ENV.fetch("PUBLISH_TEST_LOG"), "a") do |file|
                file.puts "otp_in_env=#{!secret.empty?} otp_in_argv=#{!secret.empty? && ARGV.include?(secret)}"
              end
              puts "Successfully registered gem: ace-support-core"
            else
              warn "unexpected gem command"
              exit 1
            end
          RUBY
          FileUtils.chmod(0o755, fake_gem)

          env = {
            "HOME" => home,
            "PATH" => "#{bindir}:#{ENV.fetch('PATH')}",
            "PUBLISH_TEST_BUILD_LOG" => build_log,
            "PUBLISH_TEST_LOG" => log,
          }
          yield env, log
        ensure
          File.readlines(build_log, chomp: true).each { |artifact| FileUtils.rm_f(artifact) } if File.exist?(build_log)
        end
      end
    end
  end
end

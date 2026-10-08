# frozen_string_literal: true
require "open3"
require "tmpdir"
require "fileutils"

# Shared process fixture only; including it never registers inherited tests.
module RubygemsPublishFixture
  SOURCE_SCRIPT = File.expand_path("../../../.ace-bin/ace-rubygems-publish", __dir__)
  SECRET = (1..6).to_a.join
  Context = Data.define(:script, :push_log, :build_log, :command_log, :root)
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

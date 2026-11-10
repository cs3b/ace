# frozen_string_literal: true
require_relative "../test_helper"
require "tmpdir"
require "fileutils"
require "open3"
require "json"
require "rbconfig"

class LabVmSystemPackagesTest < AceMonorepoE2eTestCase
  SCRIPT = File.expand_path("../../lab-vm/install-system-packages.sh", __dir__)

  def run_acquisition(stage: "", failures: 0, exit_code: 100)
    Dir.mktmpdir("snapshot-packages") do |root|
      log = File.join(root, "calls.jsonl")
      snapshot = File.join(root, "snapshot list")
      File.write(snapshot, "fixture")
      fake = <<~'SOURCE'
        require "json"
        stage = ARGV.include?("update") ? "update" : ARGV.include?("--download-only") ? "download" : "install"
        log = ENV.fetch("APT_CALLS")
        rows = File.exist?(log) ? File.readlines(log).map { |line| JSON.parse(line) } : []
        File.open(log, "a") { |f| f.puts(JSON.generate({"stage" => stage, "args" => ARGV, "pid" => Process.pid})) }
        count = rows.count { |row| row["stage"] == stage } + 1
        exit(ENV.fetch("APT_EXIT_CODE").to_i) if stage == ENV["APT_FAILURE_STAGE"] && count <= ENV.fetch("APT_FAILURE_COUNT").to_i
      SOURCE
      File.write(File.join(root, "apt-get"), "#!#{RbConfig.ruby}\n" + fake)
      File.write(File.join(root, "sleep"), "#!/bin/sh\nexit 0\n")
      File.chmod(0o755, File.join(root, "apt-get"), File.join(root, "sleep"))
      env = {"PATH" => "#{root}:#{ENV.fetch('PATH')}", "APT_CALLS" => log,
        "APT_FAILURE_STAGE" => stage, "APT_FAILURE_COUNT" => failures.to_s, "APT_EXIT_CODE" => exit_code.to_s}
      _, error, status = Open3.capture3(env, "/bin/sh", SCRIPT, snapshot, "package-a=1.2", "package-b")
      calls = File.exist?(log) ? File.readlines(log).map { |line| JSON.parse(line) } : []
      yield status, calls, error, snapshot
    end
  end

  def test_transient_download_failure_retries_before_offline_install
    run_acquisition(stage: "download", failures: 2) do |status, calls, _, snapshot|
      assert status.success?
      assert_equal %w[update download download download install], calls.map { |c| c["stage"] }
      assert_equal calls.size, calls.map { |c| c["pid"] }.uniq.size
      calls.each do |call|
        assert_includes call["args"], "Acquire::Retries=0"
        assert_includes call["args"], "Dir::Etc::sourcelist=#{snapshot}"
      end
      assert_includes calls.first["args"], "APT::Update::Error-Mode=any"
      assert_includes calls.last["args"], "--no-download"
      assert_equal ["package-a=1.2", "package-b"], calls.last["args"].last(2)
    end
  end

  def test_exhausted_download_failure_never_installs
    run_acquisition(stage: "download", failures: 9) do |status, calls|
      assert_equal 100, status.exitstatus
      assert_equal %w[update download download download], calls.map { |c| c["stage"] }
    end
  end

  def test_failed_indexes_never_download_or_install_packages
    run_acquisition(stage: "update", failures: 9) do |status, calls|
      assert_equal 100, status.exitstatus
      assert_equal %w[update update update], calls.map { |c| c["stage"] }
    end
  end

  def test_installation_failure_is_not_retried
    run_acquisition(stage: "install", failures: 9) do |status, calls|
      assert_equal 100, status.exitstatus
      assert_equal %w[update download install], calls.map { |c| c["stage"] }
    end
  end

  def test_non_apt_failure_is_not_retried
    run_acquisition(stage: "update", failures: 9, exit_code: 127) do |status, calls|
      assert_equal 127, status.exitstatus
      assert_equal ["update"], calls.map { |c| c["stage"] }
    end
  end
end

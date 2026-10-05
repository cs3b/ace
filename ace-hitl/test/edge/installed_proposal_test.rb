# frozen_string_literal: true

require "test_helper"
require "open3"
require "rbconfig"
require "rubygems/package"
require "set"
require "digest"
require "shellwords"

class InstalledProposalTest < AceHitlTestCase
  ROOT = File.expand_path("../../..", __dir__)

  # Evaluate freshly in package cwd; RubyGems' cached gemspec loader can
  # retain a file manifest produced from a different working directory.
  def load_source_gemspec(path)
    Dir.chdir(File.dirname(path)) do
      spec = eval(File.read(path), TOPLEVEL_BINDING, path)
      raise "invalid source gemspec: #{path}" unless spec.is_a?(Gem::Specification)
      spec.loaded_from = path
      spec
    end
  end

  def assert_installed_specs(entries, manifest, home)
    entries.each do |entry|
      next if entry["default"]
      assert entry.fetch("path").start_with?(home + "/"), "consumer loaded outside isolated GEM_HOME: #{entry}"
      built = manifest.find { |item| item["name"] == entry["name"] }
      refute_nil built, "loaded dependency absent from the built closure: #{entry}"
      assert_equal built.fetch("version"), entry.fetch("version")
      installed_archive = File.join(home, "cache", File.basename(built.fetch("archive")))
      assert File.file?(installed_archive), "missing installed archive provenance: #{entry}"
      assert_equal built.fetch("sha256"), Digest::SHA256.file(installed_archive).hexdigest
    end
  end

  def test_installed_controlled_sixteen_hour_restart_executes_exactly_once
    skip "requires explicit ACE_INSTALL_PROPOSAL=1" unless ENV["ACE_INSTALL_PROPOSAL"] == "1"
    scratch = if ENV["ACE_INSTALL_PROPOSAL_RETAIN"]
      File.join(File.expand_path(ENV.fetch("ACE_INSTALL_PROPOSAL_RETAIN")), "run-#{SecureRandom.hex(6)}")
    else
      Dir.mktmpdir("ace-proposal-install", "/tmp")
    end
    FileUtils.mkdir_p(scratch)
    scratch = File.realpath(scratch)
    refute scratch.start_with?(ROOT + "/"), "installed consumer must run outside the checkout"
    puts "Installed SC3 artifacts: #{scratch}" if ENV["ACE_INSTALL_PROPOSAL_RETAIN"]
    pool = File.join(scratch, "packages")
    FileUtils.mkdir_p(pool)
    home = File.join(scratch, "gems")
    refute File.exist?(home), "installed consumer requires an empty GEM_HOME"
    specs = Dir.glob(File.join(ROOT, "ace-*/*.gemspec")).to_h { |path| s = load_source_gemspec(path); [s.name, s] }
    closure = Set.new
    collect = lambda do |name|
      return unless closure.add?(name)
      (specs[name] || Gem::Specification.find_by_name(name)).runtime_dependencies.each { |dep| collect.call(dep.name) }
    end
    %w[ace-hitl ace-hitl-hermes ace-lab].each { |name| collect.call(name) }
    manifest = closure.sort.map do |name|
      archive = nil
      spec = specs[name] || Gem::Specification.find_by_name(name)
      if specs[name]
        archive = File.join(pool, "#{spec.full_name}.gem")
        Dir.chdir(File.join(ROOT, name)) { Gem::Package.build(spec, false, false, archive) }
      elsif !spec.default_gem?
        assert File.file?(spec.cache_file), "missing local archive #{spec.full_name}; no network fallback"
        archive = File.join(pool, File.basename(spec.cache_file))
        FileUtils.cp(spec.cache_file, archive)
      end
      {"name" => name, "version" => spec.version.to_s, "default" => spec.default_gem?,
       "archive" => archive, "sha256" => archive && Digest::SHA256.file(archive).hexdigest}
    end
    File.write(File.join(scratch, "artifacts.json"), JSON.pretty_generate(manifest))
    env = {"GEM_HOME" => home, "GEM_PATH" => home, "BUNDLE_GEMFILE" => nil, "BUNDLE_BIN_PATH" => nil,
      "BUNDLER_SETUP" => nil, "RUBYOPT" => nil, "RUBYLIB" => nil, "PROJECT_ROOT_PATH" => nil,
      "ACE_PROJECT_ROOT" => nil, "ACE_TMUX_SESSION" => nil, "ACE_TMUX_WINDOW" => nil,
      "TMUX" => nil, "TMUX_PANE" => nil}
    %w[ace-hitl-hermes ace-lab].each do |name|
      out, status = Open3.capture2e(env, RbConfig.ruby, "-S", "gem", "install", "--local", "--no-document",
        File.join(pool, "#{specs.fetch(name).full_name}.gem"), chdir: pool)
      assert status.success?, "local install failed: #{out}"
    end
    consumer = File.join(scratch, "consumer.rb")
    FileUtils.cp(File.join(__dir__, "../support/installed_proposal/consumer.rb"), consumer)
    source_head, source_status = Open3.capture2("git", "rev-parse", "HEAD", chdir: ROOT)
    assert source_status.success?, "source revision unavailable"
    File.write(File.join(scratch, "build-provenance.json"), JSON.pretty_generate(
      "source_head" => source_head.strip, "fixture_sha256" => Digest::SHA256.file(consumer).hexdigest,
      "ruby" => RbConfig.ruby, "ruby_version" => RUBY_VERSION,
      "ruby_sha256" => Digest::SHA256.file(RbConfig.ruby).hexdigest,
      "scope" => "controlled one-host current-UID local mode; no live Telegram or protected Herdr acceptance"))
    socket = "ace-sc3-#{Process.pid}-#{SecureRandom.hex(4)}"
    # The bash remains the pane owner; the installed consumer is its child.
    # This log is the standalone fixture's startup diagnostic, not ACE CLI output.
    consumer_log = File.join(scratch, "consumer.log")
    consumer_status = File.join(scratch, "consumer-status")
    command = Shellwords.join([RbConfig.ruby, consumer, "main", scratch]) +
      " > #{Shellwords.escape(consumer_log)} 2>&1; fixture_status=$?; " +
      "printf '%s\\n' \"$fixture_status\" > #{Shellwords.escape(consumer_status)}; sleep 1"
    out, status = Open3.capture2e(env, "tmux", "-L", socket, "-f", "/dev/null", "new-session", "-d",
      "-s", "sc3", "-c", scratch, Shellwords.join(["/bin/bash", "-c", command]))
    assert status.success?, "isolated tmux launch failed: #{out}"
    result_path = File.join(scratch, "result.json")
    deadline = Process.clock_gettime(Process::CLOCK_MONOTONIC) + 90
    until File.file?(result_path) && File.file?(consumer_status)
      if File.file?(consumer_status) && !File.file?(result_path)
        flunk "installed consumer exited without a result: #{File.read(consumer_log)}"
      end
      if Process.clock_gettime(Process::CLOCK_MONOTONIC) >= deadline
        diagnostic = File.file?(consumer_log) ? File.read(consumer_log) : "no consumer diagnostic"
        flunk "installed consumer did not terminate within its bounded scenario: #{diagnostic}"
      end
      sleep 0.1
    end
    result = JSON.parse(File.read(result_path))
    if ENV["ACE_INSTALL_PROPOSAL_RETAIN"]
      receipts = File.join(ROOT, ".ace-local/installed-sc3")
      FileUtils.mkdir_p(receipts)
      File.write(File.join(receipts, "#{File.basename(scratch)}.json"),
        JSON.pretty_generate("artifacts" => scratch, "manifest" => manifest, "result" => result))
    end
    assert_equal "0", File.read(consumer_status).strip, JSON.pretty_generate(result)
    assert File.file?(File.join(scratch, "completed")), "missing final consumer exit manifest"
    assert result["success"], JSON.pretty_generate(result)
    assert_equal 16 * 3600, result.fetch("window_seconds")
    assert_equal 1, result.fetch("effect_count")
    assert_equal "succeeded", result.fetch("outcome")
    assert_equal "approved-by-silence", result.fetch("decision")
    assert_operator result.fetch("checks"), :>=, 20
    assert_installed_specs(result.fetch("loaded_specs"), manifest, home)
    refute result.fetch("features").any? { |path| path.start_with?(ROOT + "/") }
    processes = File.readlines(File.join(scratch, "processes.jsonl")).map { |line| JSON.parse(line) }
    assert_operator processes.select { |entry| entry["mode"] == "service" }.map { |entry| entry["pid"] }.uniq.size, :>=, 3
    assert_operator processes.select { |entry| entry["mode"] == "actor" }.map { |entry| entry["pid"] }.uniq.size, :>=, 4
    processes.each do |entry|
      entry.fetch("gem_paths").each { |path| assert path.start_with?(home + "/"), "child loaded outside isolated home: #{path}" }
      assert_installed_specs(entry.fetch("loaded_specs"), manifest, home)
      refute entry.fetch("features").any? { |path| path.start_with?(ROOT + "/") }
      entry.fetch("features").select { |path| path.include?("/lib/ace/") }.each do |path|
        assert path.start_with?(home + "/"), "ACE source fallback outside installed home: #{path}"
      end
    end
    processes.group_by { |entry| entry["pid"] }.each_value do |entries|
      assert_equal %w[exit start], entries.map { |entry| entry["phase"] }.sort,
        "missing final loaded-source manifest for child: #{entries.first}"
      assert_equal entries.first.fetch("identity"), entries.last.fetch("identity"), "child process birth changed"
    end
  ensure
    if scratch && File.directory?(scratch) && $!
      File.write(File.join(scratch, "parent-failure.json"), JSON.pretty_generate(
        "class" => $!.class.name, "reason" => $!.message))
    end
    Open3.capture2e("tmux", "-L", socket, "kill-server") if socket
    FileUtils.remove_entry(scratch) if scratch && File.exist?(scratch) && !ENV["ACE_INSTALL_PROPOSAL_RETAIN"]
  end
end

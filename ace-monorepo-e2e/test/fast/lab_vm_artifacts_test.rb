# frozen_string_literal: true

require_relative "../test_helper"
require "tmpdir"
require "fileutils"
require "digest"
require "json"
require "open3"
require "base64"

class LabVmArtifactsTest < AceMonorepoE2eTestCase
  def setup
    @root = Dir.mktmpdir("lab-artifacts")
    @bin = File.join(@root, "ace-monorepo-e2e/bin")
    @fixture = File.join(@root, "ace-monorepo-e2e/lab-vm")
    @cache = File.join(@root, ".ace-local/lab-vm/artifacts")
    FileUtils.mkdir_p([@bin, File.join(@fixture, "pi"), @cache], mode: 0o700)
    FileUtils.cp(File.expand_path("../../bin/lab-vm-artifacts", __dir__), @bin)
    @data = "verified fixture bytes"
    digest = Digest::SHA256.hexdigest(@data)
    %w[ruby.tar.gz node.tar.xz zig.tar.xz rustup-init channel.toml].each { |name| File.write(File.join(@cache, name), @data) }
    release = {"schema" => "ace-e2e-release/v1", "gems" => [],
      "ruby_source" => {"url" => "https://example.test/ruby.tar.gz", "sha256" => digest},
      "node" => {"url" => "https://example.test/node.tar.xz", "sha256" => digest},
      "zig" => {"url" => "https://example.test/zig.tar.xz", "sha256" => digest},
      "rustup" => {"url" => "https://example.test/rustup-init", "sha256" => digest,
        "channel_manifest_url" => "https://static.rust-lang.org/channel.toml", "channel_manifest_sha256" => digest},
      "pi" => {"package" => "pi-test", "version" => "1.0.0", "lockfile" => "pi/package-lock.json"}}
    File.write(File.join(@fixture, "release-manifest.json"), JSON.generate(release))
    @lock = {"packages" => {"" => {"dependencies" => {"pi-test" => "1.0.0"}},
      "node_modules/pi-test" => {"resolved" => "https://registry.npmjs.org/pi-test/-/pi-test.tgz", "integrity" => "sha512-#{Base64.strict_encode64('a' * 64)}"}}}
    write_lock
  end

  def teardown
    FileUtils.remove_entry(@root) if @root && File.directory?(@root)
  end

  def write_lock
    File.write(File.join(@fixture, "pi/package-lock.json"), JSON.generate(@lock))
  end

  def run_fetcher
    Open3.capture3("python3", File.join(@bin, "lab-vm-artifacts"))
  end

  def test_reuses_only_verified_cached_inputs
    out, err, result = run_fetcher
    assert result.success?, err
    assert_equal 5, JSON.parse(out).fetch("cached")
    File.unlink(File.join(@cache, "ruby.tar.gz"))
    File.symlink("/dev/null", File.join(@cache, "ruby.tar.gz"))
    _out, err, result = run_fetcher
    refute result.success?
    assert_includes err, "artifact is a symlink"
  end

  def test_missing_npm_integrity_fails_before_any_download
    @lock["packages"]["node_modules/pi-test"].delete("integrity")
    write_lock
    _out, err, result = run_fetcher
    refute result.success?
    assert_includes err, "unpinned npm artifact"
    assert_equal @data, File.read(File.join(@cache, "ruby.tar.gz"))
  end

  def test_local_candidate_is_pinned_and_never_downloaded_from_rubygems
    path = File.join(@fixture, "release-manifest.json")
    release = JSON.parse(File.read(path))
    release["gems"] << {"name" => "ace-lab", "version" => "0.14.2.pre.test",
      "source" => "local", "source_commit" => "a" * 40, "sha256" => Digest::SHA256.hexdigest(@data)}
    File.write(path, JSON.generate(release))
    File.write(File.join(@cache, "ace-lab-0.14.2.pre.test.gem"), @data)
    out, err, result = run_fetcher
    assert result.success?, err
    assert_equal 6, JSON.parse(out).fetch("cached")
    release["gems"][0]["source_commit"] = "not-a-commit"
    File.write(path, JSON.generate(release))
    _out, err, result = run_fetcher
    refute result.success?
    assert_includes err, "invalid local gem build source"
  end

  def test_missing_local_candidate_is_built_and_its_hash_is_verified
    path = File.join(@fixture, "release-manifest.json")
    release = JSON.parse(File.read(path))
    release["gems"] << {"name" => "ace-lab", "version" => "0.14.2.pre.test",
      "source" => "local", "source_commit" => "a" * 40, "sha256" => Digest::SHA256.hexdigest(@data)}
    File.write(path, JSON.generate(release))
    builder = File.join(@bin, "lab-vm-build-gem")
    File.write(builder, <<~PY)
      #!/usr/bin/env python3
      import pathlib, sys
      root = pathlib.Path(__file__).resolve().parents[2]
      target = root / '.ace-local/lab-vm/artifacts' / (sys.argv[1] + '-' + sys.argv[3] + '.gem')
      target.write_bytes(b'verified fixture bytes')
    PY
    File.chmod(0o700, builder)
    out, err, result = run_fetcher
    assert result.success?, err
    assert_equal 1, JSON.parse(out).fetch("built")
    File.unlink(File.join(@cache, "ace-lab-0.14.2.pre.test.gem"))
    release["gems"][0]["sha256"] = "0" * 64
    File.write(path, JSON.generate(release))
    _out, err, result = run_fetcher
    refute result.success?
    assert_includes err, "local build SHA-256 mismatch"
  end
end

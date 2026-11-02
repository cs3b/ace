# frozen_string_literal: true

require_relative "../test_helper"
require_relative "../../lab-vm/native-cache"
require "tmpdir"
require "fileutils"
require "digest"

class LabVmNativeCacheTest < AceMonorepoE2eTestCase
  def setup
    @dir = Dir.mktmpdir("ace-native-cache")
    File.write(File.join(@dir, "herdr"), "binary")
    File.write(File.join(@dir, "provenance.json"), "receipt")
    @manifest = {"artifact_sha256" => Digest::SHA256.hexdigest("binary"),
                 "provenance_sha256" => Digest::SHA256.hexdigest("receipt")}
  end

  def teardown
    FileUtils.remove_entry(@dir) if @dir && File.directory?(@dir)
  end

  def test_accepts_exact_verified_files
    assert LabVmNativeCache.verify!(@dir, @manifest)
  end

  def test_rejects_tampered_or_missing_artifact
    File.write(File.join(@dir, "herdr"), "different")
    assert_raises(ArgumentError) { LabVmNativeCache.verify!(@dir, @manifest) }
    File.unlink(File.join(@dir, "herdr"))
    assert_raises(ArgumentError) { LabVmNativeCache.verify!(@dir, @manifest) }
  end

  def test_rejects_symlinks_extra_files_and_insecure_directory
    artifact = File.join(@dir, "herdr")
    File.unlink(artifact)
    File.symlink(File.join(@dir, "provenance.json"), artifact)
    assert_raises(ArgumentError) { LabVmNativeCache.verify!(@dir, @manifest) }
    File.unlink(artifact)
    File.write(artifact, "binary")
    File.write(File.join(@dir, "extra"), "unexpected")
    assert_raises(ArgumentError) { LabVmNativeCache.verify!(@dir, @manifest) }
    File.unlink(File.join(@dir, "extra"))
    File.chmod(0o755, @dir)
    assert_raises(ArgumentError) { LabVmNativeCache.verify!(@dir, @manifest) }
  ensure
    File.chmod(0o700, @dir) if @dir && File.directory?(@dir)
  end

  def test_rejects_invalid_or_incomplete_manifest
    assert_raises(ArgumentError) { LabVmNativeCache.verify!(@dir, @manifest.merge("artifact_sha256" => "bad")) }
    assert_raises(KeyError) { LabVmNativeCache.verify!(@dir, @manifest.reject { |key, _| key == "provenance_sha256" }) }
  end
end

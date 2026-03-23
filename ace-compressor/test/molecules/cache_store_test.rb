# frozen_string_literal: true

require "tmpdir"
require "fileutils"
require_relative "../test_helper"

class CacheStoreTest < AceCompressorTestCase
  def setup
    super
    @tmp = Dir.mktmpdir("ace_compressor_cache_store")
  end

  def teardown
    FileUtils.rm_rf(@tmp)
    super
  end

  def test_manifest_uses_source_path_for_stable_key
    store = Ace::Compressor::Molecules::CacheStore.new(cache_root: @tmp, project_root: Dir.pwd)
    content = "# Hello\n\nWorld.\n"

    # Write same content to two different tmpdir paths
    dir1 = Dir.mktmpdir("ace_compressor_labels_a")
    dir2 = Dir.mktmpdir("ace_compressor_labels_b")
    source1 = File.join(dir1, "source.md")
    source2 = File.join(dir2, "source.md")
    File.write(source1, content)
    File.write(source2, content)

    # Without labels: different paths → different keys
    manifest_a = store.manifest(mode: "exact", sources: [{content_path: source1, source_path: source1, source_kind: "file"}])
    manifest_b = store.manifest(mode: "exact", sources: [{content_path: source2, source_path: source2, source_kind: "file"}])
    refute_equal manifest_a["key"], manifest_b["key"]

    manifest_logical_a = store.manifest(mode: "exact", sources: [{content_path: source1, source_path: "project", source_kind: "preset"}])
    manifest_logical_b = store.manifest(mode: "exact", sources: [{content_path: source2, source_path: "project", source_kind: "preset"}])
    assert_equal manifest_logical_a["key"], manifest_logical_b["key"]
  ensure
    FileUtils.rm_rf(dir1) if dir1
    FileUtils.rm_rf(dir2) if dir2
  end

  def test_manifest_without_source_metadata_uses_expanded_path
    store = Ace::Compressor::Molecules::CacheStore.new(cache_root: @tmp, project_root: Dir.pwd)
    source = File.join(@tmp, "file.md")
    File.write(source, "content")

    manifest = store.manifest(mode: "exact", sources: [source])
    assert_equal File.expand_path(source), manifest["sources"].first["path"]
  end

  def test_manifest_with_source_metadata_uses_source_path
    store = Ace::Compressor::Molecules::CacheStore.new(cache_root: @tmp, project_root: Dir.pwd)
    source = File.join(@tmp, "file.md")
    File.write(source, "content")

    manifest = store.manifest(mode: "exact", sources: [{content_path: source, source_path: "project", source_kind: "preset"}])
    assert_equal "project", manifest["sources"].first["path"]
  end

  def test_canonical_paths_handles_source_outside_project_root
    store = Ace::Compressor::Molecules::CacheStore.new(cache_root: @tmp, project_root: Dir.pwd)
    external_source = File.join(Dir.mktmpdir("ace_compressor_external"), "resolved.md")
    File.write(external_source, "# Bundled")

    manifest = store.manifest(mode: "exact", sources: [external_source])
    paths = store.canonical_paths(mode: "exact", sources: [external_source], manifest_key: manifest["key"])

    assert_includes paths[:pack_path], "resolved"
    assert_includes paths[:pack_path], ".exact.pack"
  ensure
    FileUtils.rm_rf(File.dirname(external_source)) if external_source
  end

  def test_canonical_paths_uses_logical_source_for_bundle_inputs
    store = Ace::Compressor::Molecules::CacheStore.new(cache_root: @tmp, project_root: Dir.pwd)
    bundled = File.join(@tmp, "resolved.md")
    File.write(bundled, "# Bundled")

    manifest = store.manifest(mode: "exact", sources: [{content_path: bundled, source_path: "wfi://task/draft", source_kind: "workflow"}])
    paths = store.canonical_paths(
      mode: "exact",
      sources: [{content_path: bundled, source_path: "wfi://task/draft", source_kind: "workflow"}],
      manifest_key: manifest["key"]
    )

    assert_includes paths[:pack_path], "wfi/task/draft"
  end
end

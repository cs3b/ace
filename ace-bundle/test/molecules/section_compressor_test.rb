# frozen_string_literal: true

require "test_helper"

class SectionCompressorTest < AceTestCase
  def setup
    @compressor = Ace::Bundle::Molecules::SectionCompressor.new(default_mode: "per-source")
  end

  def test_off_mode_skips_compression
    compressor = Ace::Bundle::Molecules::SectionCompressor.new(default_mode: "off")
    bundle = make_bundle_with_md_section("# Hello\n\nWorld.\n")

    compressor.call(bundle)

    content = bundle.sections["docs"][:_processed_files].first[:content]
    assert_includes content, "# Hello"
    refute_includes content, "FILE|"
  end

  def test_per_source_compresses_each_file
    bundle = make_bundle_with_md_section("# Title\n\nA summary line.\n")

    @compressor.call(bundle)

    file = bundle.sections["docs"][:_processed_files].first
    assert_includes file[:content], "FILE|docs/readme.md"
    assert_includes file[:content], "SEC|title"
    assert file[:compressed]
  end

  def test_merged_combines_files_into_one
    compressor = Ace::Bundle::Molecules::SectionCompressor.new(default_mode: "merged")
    bundle = make_bundle_with_files([
      { path: "a.md", content: "# File A\n\nContent A.\n" },
      { path: "b.md", content: "# File B\n\nContent B.\n" }
    ])

    compressor.call(bundle)

    files = bundle.sections["docs"][:_processed_files]
    assert_equal 1, files.size
    assert_includes files.first[:content], "FILE|a.md"
    assert_includes files.first[:content], "FILE|b.md"
    assert files.first[:compressed]
  end

  def test_non_markdown_files_pass_through
    bundle = make_bundle_with_files([
      { path: "lib/app.rb", content: "def hello; end" },
      { path: "docs/guide.md", content: "# Guide\n\nContent.\n" }
    ])

    @compressor.call(bundle)

    files = bundle.sections["docs"][:_processed_files]
    rb_file = files.find { |f| f[:path] == "lib/app.rb" }
    md_file = files.find { |f| f[:path] == "docs/guide.md" }

    assert_equal "def hello; end", rb_file[:content]
    refute rb_file[:compressed]

    assert_includes md_file[:content], "FILE|docs/guide.md"
    assert md_file[:compressed]
  end

  def test_per_source_preserves_original_file_order_for_mixed_sections
    bundle = make_bundle_with_files([
      { path: "a.md", content: "# File A\n\nContent A.\n" },
      { path: "lib/app.rb", content: "def hello; end" },
      { path: "c.md", content: "# File C\n\nContent C.\n" }
    ])

    @compressor.call(bundle)

    files = bundle.sections["docs"][:_processed_files]
    assert_equal ["a.md", "lib/app.rb", "c.md"], files.map { |file| file[:path] }
    assert files[0][:compressed]
    refute files[1][:compressed]
    assert files[2][:compressed]
  end

  def test_merged_preserves_passthrough_file_positions
    compressor = Ace::Bundle::Molecules::SectionCompressor.new(default_mode: "merged")
    bundle = make_bundle_with_files([
      { path: "lib/pre.rb", content: "PRE = true" },
      { path: "a.md", content: "# File A\n\nContent A.\n" },
      { path: "b.md", content: "# File B\n\nContent B.\n" },
      { path: "lib/post.rb", content: "POST = true" }
    ])

    compressor.call(bundle)

    files = bundle.sections["docs"][:_processed_files]
    assert_equal ["lib/pre.rb", "a.md", "lib/post.rb"], files.map { |file| file[:path] }
    assert_equal "PRE = true", files[0][:content]
    assert files[1][:compressed]
    assert_includes files[1][:content], "FILE|a.md"
    assert_includes files[1][:content], "FILE|b.md"
    assert_equal "POST = true", files[2][:content]
  end

  def test_section_level_override
    compressor = Ace::Bundle::Molecules::SectionCompressor.new(default_mode: "per-source")
    bundle = make_bundle_with_md_section("# Title\n\nText.\n")
    bundle.sections["docs"][:params] = { "compress" => "off" }

    compressor.call(bundle)

    content = bundle.sections["docs"][:_processed_files].first[:content]
    assert_includes content, "# Title"
    refute_includes content, "FILE|"
  end

  def test_no_sections_is_noop_without_source
    bundle = Ace::Bundle::Models::BundleData.new(content: "hello")
    result = @compressor.call(bundle)
    assert_equal "hello", result.content
  end

  def test_content_only_bundle_with_real_file_gets_compressed
    Dir.mktmpdir("ace_content_compress") do |tmpdir|
      md_path = File.join(tmpdir, "workflow.md")
      File.write(md_path, "# Workflow\n\nSome instructions here.\n")

      bundle = Ace::Bundle::Models::BundleData.new(content: File.read(md_path))
      bundle.metadata[:source] = md_path

      @compressor.call(bundle)

      assert_includes bundle.content, "FILE|#{md_path}"
      assert bundle.metadata[:compressed]
    end
  end

  def test_content_only_bundle_off_mode_skips_compression
    Dir.mktmpdir("ace_content_compress") do |tmpdir|
      md_path = File.join(tmpdir, "workflow.md")
      File.write(md_path, "# Workflow\n\nSome instructions here.\n")

      compressor = Ace::Bundle::Molecules::SectionCompressor.new(default_mode: "off")
      bundle = Ace::Bundle::Models::BundleData.new(content: File.read(md_path))
      bundle.metadata[:source] = md_path

      compressor.call(bundle)

      assert_includes bundle.content, "# Workflow"
      refute bundle.metadata[:compressed]
    end
  end

  def test_content_only_bundle_non_compressible_source_skips
    Dir.mktmpdir("ace_content_compress") do |tmpdir|
      rb_path = File.join(tmpdir, "app.rb")
      File.write(rb_path, "def hello; end")

      bundle = Ace::Bundle::Models::BundleData.new(content: File.read(rb_path))
      bundle.metadata[:source] = rb_path

      @compressor.call(bundle)

      assert_equal "def hello; end", bundle.content
      refute bundle.metadata[:compressed]
    end
  end

  def test_content_only_bundle_cache_hit_returns_same_output
    cache_dir = Dir.mktmpdir("ace_bundle_content_cache")
    Dir.mktmpdir("ace_content_compress") do |tmpdir|
      md_path = File.join(tmpdir, "workflow.md")
      File.write(md_path, "# Workflow\n\nSome instructions here.\n")

      cache_store = Ace::Compressor::Molecules::CacheStore.new(cache_root: cache_dir)
      compressor = Ace::Bundle::Molecules::SectionCompressor.new(
        default_mode: "per-source", compressor_mode: "exact", cache_store: cache_store
      )

      bundle1 = Ace::Bundle::Models::BundleData.new(content: File.read(md_path))
      bundle1.metadata[:source] = md_path
      compressor.call(bundle1)
      first_result = bundle1.content

      bundle2 = Ace::Bundle::Models::BundleData.new(content: File.read(md_path))
      bundle2.metadata[:source] = md_path
      compressor.call(bundle2)
      second_result = bundle2.content

      assert_equal first_result, second_result
      assert bundle2.metadata[:compressed]
    end
  ensure
    FileUtils.rm_rf(cache_dir) if cache_dir
  end

  def test_content_only_bundle_no_source_is_noop
    bundle = Ace::Bundle::Models::BundleData.new(content: "hello")
    @compressor.call(bundle)
    assert_equal "hello", bundle.content
    refute bundle.metadata[:compressed]
  end

  def test_content_only_bundle_exact_mode_compresses
    Dir.mktmpdir("ace_content_compress") do |tmpdir|
      md_path = File.join(tmpdir, "workflow.md")
      File.write(md_path, "# Workflow\n\nSome instructions here.\n")

      compressor = Ace::Bundle::Molecules::SectionCompressor.new(
        default_mode: "per-source", compressor_mode: "exact"
      )
      bundle = Ace::Bundle::Models::BundleData.new(content: File.read(md_path))
      bundle.metadata[:source] = md_path

      compressor.call(bundle)

      assert_includes bundle.content, "FILE|#{md_path}"
      assert bundle.metadata[:compressed]
    end
  end

  def test_compressing_frontmatter_only_files_with_other_files
    bundle = make_bundle_with_files([
      { path: "test-context.md", content: "---\ntitle: Frontmatter Only\n---\n" },
      { path: "docs/readme.md", content: "# Title\n\nA summary line.\n" }
    ])

    @compressor.call(bundle)

    files = bundle.sections["docs"][:_processed_files]
    frontmatter_file = files.find { |f| f[:path] == "test-context.md" }
    readme_file = files.find { |f| f[:path] == "docs/readme.md" }

    assert_includes frontmatter_file[:content], "title: Frontmatter Only"
    assert_includes readme_file[:content], "FILE|docs/readme.md"
  end

  def test_compressor_mode_defaults_to_exact
    compressor = Ace::Bundle::Molecules::SectionCompressor.new(default_mode: "per-source")
    bundle = make_bundle_with_md_section("# Title\n\nA summary line.\n")

    compressor.call(bundle)

    file = bundle.sections["docs"][:_processed_files].first
    assert_includes file[:content], "FILE|docs/readme.md"
    assert file[:compressed]
  end

  def test_compressor_mode_exact_explicit
    compressor = Ace::Bundle::Molecules::SectionCompressor.new(default_mode: "per-source", compressor_mode: "exact")
    bundle = make_bundle_with_md_section("# Title\n\nA summary line.\n")

    compressor.call(bundle)

    file = bundle.sections["docs"][:_processed_files].first
    assert_includes file[:content], "FILE|docs/readme.md"
    assert file[:compressed]
  end

  def test_compressor_mode_exact_works
    compressor = Ace::Bundle::Molecules::SectionCompressor.new(default_mode: "per-source", compressor_mode: "exact")
    bundle = make_bundle_with_md_section("# Title\n\nA summary line.\n")

    compressor.call(bundle)

    file = bundle.sections["docs"][:_processed_files].first
    assert_includes file[:content], "FILE|docs/readme.md"
    assert file[:compressed]
  end

  def test_compressor_mode_unknown_raises
    error = assert_raises(ArgumentError) do
      Ace::Bundle::Molecules::SectionCompressor.new(default_mode: "per-source", compressor_mode: "bogus")
    end
    assert_includes error.message, "Unknown compressor_mode"
  end

  def test_section_level_compressor_source_scope_override
    compressor = Ace::Bundle::Molecules::SectionCompressor.new(default_mode: "per-source")
    bundle = make_bundle_with_md_section("# Title\n\nText.\n")
    bundle.sections["docs"][:params] = { "compressor_source_scope" => "off" }

    compressor.call(bundle)

    content = bundle.sections["docs"][:_processed_files].first[:content]
    assert_includes content, "# Title"
    refute_includes content, "FILE|"
  end

  def test_backward_compat_section_compress_param
    compressor = Ace::Bundle::Molecules::SectionCompressor.new(default_mode: "off")
    bundle = make_bundle_with_md_section("# Title\n\nText.\n")
    bundle.sections["docs"][:params] = { "compress" => "per-source" }

    compressor.call(bundle)

    file = bundle.sections["docs"][:_processed_files].first
    assert_includes file[:content], "FILE|docs/readme.md"
    assert file[:compressed]
  end

  def test_section_compressor_source_scope_takes_precedence_over_compress
    compressor = Ace::Bundle::Molecules::SectionCompressor.new(default_mode: "off")
    bundle = make_bundle_with_md_section("# Title\n\nText.\n")
    bundle.sections["docs"][:params] = {
      "compressor_source_scope" => "off",
      "compress" => "per-source"
    }

    compressor.call(bundle)

    content = bundle.sections["docs"][:_processed_files].first[:content]
    assert_includes content, "# Title"
    refute_includes content, "FILE|"
  end

  def test_per_source_cache_hit_skips_recompression
    cache_dir = Dir.mktmpdir("ace_bundle_section_cache")
    cache_store = Ace::Compressor::Molecules::CacheStore.new(cache_root: cache_dir)
    compressor = Ace::Bundle::Molecules::SectionCompressor.new(
      default_mode: "per-source", compressor_mode: "exact", cache_store: cache_store
    )
    content = "# Title\n\nA summary line.\n"
    bundle1 = make_bundle_with_md_section(content)
    bundle2 = make_bundle_with_md_section(content)

    # First call: cache miss, compresses
    compressor.call(bundle1)
    first_result = bundle1.sections["docs"][:_processed_files].first[:content]
    assert_includes first_result, "FILE|docs/readme.md"

    # Second call: cache hit, same output without recompression
    compressor.call(bundle2)
    second_result = bundle2.sections["docs"][:_processed_files].first[:content]
    assert_equal first_result, second_result
    assert bundle2.sections["docs"][:_processed_files].first[:compressed]
  ensure
    FileUtils.rm_rf(cache_dir) if cache_dir
  end

  def test_merged_cache_hit_skips_recompression
    cache_dir = Dir.mktmpdir("ace_bundle_section_cache")
    cache_store = Ace::Compressor::Molecules::CacheStore.new(cache_root: cache_dir)
    compressor = Ace::Bundle::Molecules::SectionCompressor.new(
      default_mode: "merged", compressor_mode: "exact", cache_store: cache_store
    )
    files = [
      { path: "a.md", content: "# File A\n\nContent A.\n" },
      { path: "b.md", content: "# File B\n\nContent B.\n" }
    ]
    bundle1 = make_bundle_with_files(files)
    bundle2 = make_bundle_with_files(files)

    compressor.call(bundle1)
    first_result = bundle1.sections["docs"][:_processed_files].first[:content]
    assert_includes first_result, "FILE|a.md"

    compressor.call(bundle2)
    second_result = bundle2.sections["docs"][:_processed_files].first[:content]
    assert_equal first_result, second_result
  ensure
    FileUtils.rm_rf(cache_dir) if cache_dir
  end

  def test_per_source_cache_miss_on_changed_content
    cache_dir = Dir.mktmpdir("ace_bundle_section_cache")
    cache_store = Ace::Compressor::Molecules::CacheStore.new(cache_root: cache_dir)
    compressor = Ace::Bundle::Molecules::SectionCompressor.new(
      default_mode: "per-source", compressor_mode: "exact", cache_store: cache_store
    )
    bundle1 = make_bundle_with_md_section("# Original\n\nOriginal content.\n")
    bundle2 = make_bundle_with_md_section("# Changed\n\nDifferent content.\n")

    compressor.call(bundle1)
    first_result = bundle1.sections["docs"][:_processed_files].first[:content]

    compressor.call(bundle2)
    second_result = bundle2.sections["docs"][:_processed_files].first[:content]

    refute_equal first_result, second_result
    assert_includes second_result, "FILE|docs/readme.md"
  ensure
    FileUtils.rm_rf(cache_dir) if cache_dir
  end

  def test_injectable_cache_store
    cache_dir = Dir.mktmpdir("ace_bundle_section_cache")
    custom_store = Ace::Compressor::Molecules::CacheStore.new(cache_root: cache_dir)
    compressor = Ace::Bundle::Molecules::SectionCompressor.new(
      default_mode: "per-source", compressor_mode: "exact", cache_store: custom_store
    )
    bundle = make_bundle_with_md_section("# Title\n\nA summary line.\n")

    compressor.call(bundle)

    file = bundle.sections["docs"][:_processed_files].first
    assert_includes file[:content], "FILE|docs/readme.md"
    assert file[:compressed]
  ensure
    FileUtils.rm_rf(cache_dir) if cache_dir
  end

  private

  def make_bundle_with_md_section(content)
    make_bundle_with_files([{ path: "docs/readme.md", content: content }])
  end

  def make_bundle_with_files(files)
    bundle = Ace::Bundle::Models::BundleData.new
    bundle.add_section("docs", {
      title: "Documentation",
      _processed_files: files.map { |f| { path: f[:path], content: f[:content] } }
    })
    bundle
  end
end

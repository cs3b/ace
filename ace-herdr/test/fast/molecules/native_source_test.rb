# frozen_string_literal: true

require "test_helper"
require "rubygems/package"
require "digest"

class NativeSourceTest < Minitest::Test
  Source = Ace::Herdr::Molecules::NativeSource

  def setup
    @source = Source.new
    @tmp = File.realpath(Dir.mktmpdir("native-source-values"))
  end

  def teardown
    FileUtils.remove_entry(@tmp)
  end

  def fixture_bytes(target = "x86_64-unknown-linux-musl")
    bytes = "\0".b * 64
    bytes[0, 7] = "\x7fELF\x02\x01\x01".b
    bytes[16, 2] = [2].pack("v")
    bytes[18, 2] = [target.start_with?("x86_64-") ? 62 : 183].pack("v")
    bytes + "CONTROLLED_SOURCE_FIXTURE_NEVER_EXECUTE"
  end

  def fixture_directory
    directory = File.join(@tmp, "artifact")
    Dir.mkdir(directory)
    bytes = fixture_bytes
    build = {"target" => "x86_64-unknown-linux-musl", "profile" => "release",
      "rust_version" => @source.selection.fetch("rust_version"), "zig_version" => @source.selection.fetch("zig_version"),
      "tools_sha256" => %w[cargo rustc zig linker].to_h { |name| [name, "a" * 64] }}
    receipt = @source.receipt(build: build, artifact: @source.artifact_record(bytes: bytes, target: build.fetch("target")))
    File.binwrite(File.join(directory, "herdr"), bytes)
    File.write(File.join(directory, "provenance.json"), JSON.pretty_generate(receipt) + "\n")
    [directory, receipt]
  end

  def rewrite_receipt(directory, receipt)
    File.write(File.join(directory, "provenance.json"), JSON.generate(receipt))
  end

  def test_packaged_selection_pins_the_exact_reviewed_source_and_patch
    assert_equal "70ee59844bccaec63e00140787bc95ff0d705ca6", @source.selection.fetch("source_commit")
    assert_equal "7b116c05bfda646af39d2524c54e70c751f57ee8", @source.selection.fetch("baseline_commit")
    assert_equal "1092eb5d6b909ef452fc4f08d9d39754a1fc7a529a126d118949db12c8585c90", @source.selection.fetch("patch_sha256")
    assert_equal @source.selection.fetch("patch_sha256"), Digest::SHA256.file(@source.patch_path).hexdigest
    refute_includes @source.selection_path, ".ace-tasks"
    assert_raises(FrozenError) { @source.selection["committer"]["name"] = "replacement" }
  end

  def test_real_gem_archive_ships_selection_patch_and_upstream_license_outside_task_tree
    package_root = File.expand_path("../../..", __dir__)
    specification = Gem::Specification.load(File.join(package_root, "ace-herdr.gemspec"))
    archive = File.join(@tmp, "source-fixture.gem")
    capture_io { Dir.chdir(package_root) { Gem::Package.build(specification, false, false, archive) } }
    extraction = File.join(@tmp, "extracted-gem")
    Gem::Package.new(archive).extract_files(extraction)
    namespace = Module.new
    load(File.join(extraction, "lib/ace/herdr/molecules/native_source.rb"), namespace)
    shipped = namespace::Ace::Herdr::Molecules::NativeSource.new
    assert_equal File.join(extraction, "lib/ace/herdr/native_source/selection.json"), shipped.selection_path
    assert_equal @source.description.fetch("source"), shipped.selection
    assert_equal @source.selection_sha256, shipped.selection_sha256
    assert File.file?(File.join(extraction, "lib/ace/herdr/native_source/HERDR-LICENSE"))
    refute Dir.exist?(File.join(extraction, ".ace-tasks"))
  end

  def test_valid_controlled_artifact_reports_observed_binary_and_receipt_digests
    directory, receipt = fixture_directory
    result = @source.verify_artifact(directory: directory)
    assert_equal receipt.fetch("artifact"), result.fetch("artifact")
    assert_equal Digest::SHA256.file(File.join(directory, "provenance.json")).hexdigest, result.fetch("provenance_sha256")
    assert_equal @source.selection_sha256, result.fetch("selection_sha256")
  end

  def test_binary_tampering_never_verifies_self_asserted_old_digest
    directory, = fixture_directory
    File.open(File.join(directory, "herdr"), "ab") { |file| file.write("changed") }
    assert_raises(Source::Error) { @source.verify_artifact(directory: directory) }
  end

  def test_unknown_nested_receipt_fields_and_wrong_types_refuse
    directory, receipt = fixture_directory
    receipt["build"]["exemption"] = true
    rewrite_receipt(directory, receipt)
    assert_raises(Source::Error) { @source.verify_artifact(directory: directory) }
    receipt["build"].delete("exemption")
    receipt["artifact"]["size"] = receipt["artifact"]["size"].to_s
    rewrite_receipt(directory, receipt)
    assert_raises(Source::Error) { @source.verify_artifact(directory: directory) }
  end

  def test_source_selection_toolchain_target_and_tool_digest_mismatches_refuse
    directory, original = fixture_directory
    changes = [lambda { |r| r["selection_sha256"] = "b" * 64 },
      lambda { |r| r["source"]["source_commit"] = "a" * 40 },
      lambda { |r| r["source"]["protocol"] = 22.0 },
      lambda { |r| r["build"]["rust_version"] = "0.0.1" },
      lambda { |r| r["build"]["target"] = "x86_64-apple-darwin" },
      lambda { |r| r["build"]["tools_sha256"]["zig"] = true }]
    changes.each do |change|
      receipt = JSON.parse(JSON.generate(original))
      change.call(receipt)
      rewrite_receipt(directory, receipt)
      assert_raises(Source::Error) { @source.verify_artifact(directory: directory) }
    end
  end

  def test_duplicate_receipt_keys_refuse
    directory, receipt = fixture_directory
    json = JSON.generate(receipt).sub('"schema":"ace.herdr.native-build/v1"', '"schema":"wrong","schema":"ace.herdr.native-build/v1"')
    File.write(File.join(directory, "provenance.json"), json)
    assert_raises(Source::Error) { @source.verify_artifact(directory: directory) }
  end

  def test_missing_partial_or_extra_output_refuses
    directory, = fixture_directory
    File.write(File.join(directory, "unfinished"), "source fixture")
    assert_raises(Source::Error) { @source.verify_artifact(directory: directory) }
    File.unlink(File.join(directory, "unfinished"))
    File.unlink(File.join(directory, "provenance.json"))
    assert_raises(Source::Error) { @source.verify_artifact(directory: directory) }
  end

  def test_symlink_artifact_refuses_without_reading_replacement
    directory, = fixture_directory
    original = File.join(directory, "herdr")
    replacement = File.join(@tmp, "replacement")
    File.rename(original, replacement)
    File.symlink(replacement, original)
    assert_raises(Source::Error) { @source.verify_artifact(directory: directory) }
  end

  def test_wrong_architecture_or_non_elf_product_refuses_even_with_matching_content_digest
    directory, receipt = fixture_directory
    bytes = fixture_bytes("aarch64-unknown-linux-musl")
    File.binwrite(File.join(directory, "herdr"), bytes)
    receipt["artifact"]["sha256"] = Digest::SHA256.hexdigest(bytes)
    rewrite_receipt(directory, receipt)
    assert_raises(Source::Error) { @source.verify_artifact(directory: directory) }
    assert_raises(Source::Error) { @source.artifact_record(bytes: "not a product", target: "x86_64-unknown-linux-musl") }
  end

  def test_packaged_patch_tampering_and_duplicate_selection_keys_refuse
    assets = File.join(@tmp, "assets")
    FileUtils.cp_r(Source::ASSETS, assets)
    File.open(File.join(assets, "guarded-prompt.patch"), "ab") { |file| file.write("changed") }
    assert_raises(Source::Error) { Source.new(assets: assets) }
    FileUtils.cp(@source.patch_path, File.join(assets, "guarded-prompt.patch"))
    selection = File.read(File.join(assets, "selection.json"))
    selection.sub!('"schema": "ace.herdr.native-source/v1"', '"schema": "wrong", "schema": "ace.herdr.native-source/v1"')
    File.write(File.join(assets, "selection.json"), selection)
    assert_raises(Source::Error) { Source.new(assets: assets) }
  end

  def test_invalid_utf8_comments_excessive_nesting_and_invalid_dates_refuse
    assets = File.join(@tmp, "strict-assets")
    FileUtils.cp_r(Source::ASSETS, assets)
    path = File.join(assets, "selection.json")
    valid = File.binread(path)
    [valid + "\xff".b, "/*comment*/" + valid, "[" * 17 + "0" + "]" * 17].each do |bytes|
      File.binwrite(path, bytes)
      assert_raises(Source::Error) { Source.new(assets: assets) }
    end
    data = JSON.parse(valid)
    [nil, 5, "2026-99-07T00:43:20+01:00"].each do |date|
      data["committer"]["date"] = date
      File.write(path, JSON.generate(data))
      assert_raises(Source::Error) { Source.new(assets: assets) }
    end
  end

  def test_selection_and_verify_public_commands_execute_only_packaged_value_owner
    command = Ace::Herdr::CLI::Commands::NativeSource.new
    stdout, = capture_io { command.call(operation: "selection") }
    assert_equal @source.selection_sha256, JSON.parse(stdout).fetch("selection_sha256")
    directory, receipt = fixture_directory
    stdout, = capture_io { command.call(operation: "verify", artifact: directory) }
    assert_equal receipt.fetch("artifact"), JSON.parse(stdout).fetch("artifact")
    assert_raises(Ace::Support::Cli::Error) { command.call(operation: "selection", artifact: directory) }
    assert_raises(Ace::Support::Cli::Error) { command.call(operation: "build", source: directory) }
  end
end

# frozen_string_literal: true

require_relative "../../test_helper"

class ReleaseManifestTest < Minitest::Test
  def setup
    @tmpdir = Dir.mktmpdir
    @source = File.join(@tmpdir, "installation-manifest.json")
  end

  def teardown
    FileUtils.remove_entry(@tmpdir) if @tmpdir && Dir.exist?(@tmpdir)
  end

  def test_valid_manifest_loads
    write_manifest(valid_manifest)

    data = Ace::Test::EndToEndRunner::Molecules::ReleaseManifest.load_validated(@source)

    assert_equal 1, data["schema_version"]
    assert_equal 2, data["packages"].size
  end

  def test_missing_file_fails
    error = assert_raises(Ace::Test::EndToEndRunner::Molecules::ReleaseManifest::Invalid) do
      Ace::Test::EndToEndRunner::Molecules::ReleaseManifest.load_validated(File.join(@tmpdir, "absent.json"))
    end
    assert_match(/missing/, error.message)
  end

  def test_unreadable_file_fails
    write_manifest(valid_manifest)
    File.chmod(0o000, @source)

    error = assert_raises(Ace::Test::EndToEndRunner::Molecules::ReleaseManifest::Invalid) do
      Ace::Test::EndToEndRunner::Molecules::ReleaseManifest.load_validated(@source)
    end
    assert_match(/not readable/, error.message)
  ensure
    File.chmod(0o644, @source)
  end

  def test_empty_file_fails
    write_manifest("")

    error = assert_raises(invalid_manifest) { load_manifest }
    assert_match(/empty/, error.message)
  end

  def test_malformed_json_fails
    write_manifest("{not json")

    error = assert_raises(invalid_manifest) { load_manifest }
    assert_match(/not valid JSON/, error.message)
  end

  def test_non_object_manifest_fails
    write_manifest([1, 2])

    error = assert_raises(invalid_manifest) { load_manifest }
    assert_match(/must be a JSON object/, error.message)
  end

  def test_unknown_top_level_field_fails
    write_manifest(valid_manifest("extra" => true))

    error = assert_raises(invalid_manifest) { load_manifest }
    assert_match(/unknown fields: extra/, error.message)
  end

  def test_unsupported_schema_version_fails
    [{}, 2, "1", nil].each do |bad|
      write_manifest(valid_manifest("schema_version" => bad))

      error = assert_raises(invalid_manifest) { load_manifest }
      assert_match(/unsupported schema_version/, error.message)
    end
  end

  def test_bad_manifest_source_sha_fails
    ["short", "G" * 40, nil, 42].each do |bad|
      write_manifest(valid_manifest("source_sha" => bad))

      error = assert_raises(invalid_manifest) { load_manifest }
      assert_match(/manifest source_sha/, error.message)
    end
  end

  def test_empty_packages_fails
    write_manifest(valid_manifest("packages" => []))

    error = assert_raises(invalid_manifest) { load_manifest }
    assert_match(/nonempty array/, error.message)
  end

  def test_duplicate_package_names_fail
    write_manifest(valid_manifest("packages" => [
      {"name" => "ace-git", "artifact_version" => "0.25.0", "source_sha" => "b" * 40},
      {"name" => "ace-git", "artifact_version" => "0.24.0", "source_sha" => "c" * 40}
    ]))

    error = assert_raises(invalid_manifest) { load_manifest }
    assert_match(/duplicate package name: ace-git/, error.message)
  end

  def test_non_ace_name_fails
    write_manifest(valid_manifest("packages" => [
      {"name" => "rake", "artifact_version" => "13.0.0", "source_sha" => "b" * 40}
    ]))

    error = assert_raises(invalid_manifest) { load_manifest }
    assert_match(/invalid ACE gem name/, error.message)
  end

  def test_requirement_as_artifact_version_fails
    ["~> 0.2", ">= 0.1", "latest", ""].each do |bad|
      write_manifest(valid_manifest("packages" => [
        {"name" => "ace-git-github", "artifact_version" => bad, "source_sha" => "b" * 40}
      ]))

      error = assert_raises(invalid_manifest) { load_manifest }
      assert_match(/artifact_version/, error.message)
    end
  end

  def test_unknown_package_field_fails
    write_manifest(valid_manifest("packages" => [
      {"name" => "ace-git", "artifact_version" => "0.25.0", "source_sha" => "b" * 40, "constraint" => "~> 0.2"}
    ]))

    error = assert_raises(invalid_manifest) { load_manifest }
    assert_match(/unknown fields: constraint/, error.message)
  end

  def test_missing_required_package_field_fails
    write_manifest(valid_manifest("packages" => [
      {"name" => "ace-git", "artifact_version" => "0.25.0"}
    ]))

    error = assert_raises(invalid_manifest) { load_manifest }
    assert_match(/source_sha/, error.message)
  end

  def test_contradictory_supersession_fails
    [{"supersedes" => ["0.27.1"]}, {"supersedes" => ["0.28.0"]}, {"supersedes" => "0.27.0"}].each do |override|
      write_manifest(valid_manifest("packages" => [
        {
          "name" => "ace-test-runner",
          "artifact_version" => "0.27.1",
          "source_sha" => "c" * 40
        }.merge(override)
      ]))

      error = assert_raises(invalid_manifest) { load_manifest }
      assert_match(/supersedes/, error.message)
    end
  end

  def test_supersedes_invalid_or_duplicate_entries_fail
    [{"supersedes" => ["~> 0.26"]}, {"supersedes" => ["0.27.0", "0.27.0"]}].each do |override|
      write_manifest(valid_manifest("packages" => [
        {
          "name" => "ace-test-runner",
          "artifact_version" => "0.27.1",
          "source_sha" => "c" * 40
        }.merge(override)
      ]))

      error = assert_raises(invalid_manifest) { load_manifest }
      assert_match(/supersedes/, error.message)
    end
  end

  def test_validate_and_copy_preserves_exact_bytes
    payload = JSON.pretty_generate(valid_manifest)
    File.write(@source, payload)
    target = File.join(@tmpdir, "nested", "dir", "release-manifest.json")

    Ace::Test::EndToEndRunner::Molecules::ReleaseManifest.validate_and_copy(
      source_path: @source, target_path: target
    )

    assert_equal File.read(@source), File.read(target)
  end

  def test_validate_and_copy_rejects_invalid_manifest
    write_manifest({"schema_version" => 2})
    target = File.join(@tmpdir, "copy.json")

    error = assert_raises(invalid_manifest) do
      Ace::Test::EndToEndRunner::Molecules::ReleaseManifest.validate_and_copy(
        source_path: @source, target_path: target
      )
    end
    assert_match(/unsupported schema_version/, error.message)
    refute File.exist?(target)
  end

  def test_validate_and_copy_enforces_required_packages
    payload = JSON.pretty_generate(valid_manifest)
    File.write(@source, payload)
    target = File.join(@tmpdir, "copy.json")

    Ace::Test::EndToEndRunner::Molecules::ReleaseManifest.validate_and_copy(
      source_path: @source, target_path: target, required_packages: %w[ace-git-github ace-test-runner]
    )
    assert File.exist?(target)

    error = assert_raises(invalid_manifest) do
      Ace::Test::EndToEndRunner::Molecules::ReleaseManifest.validate_and_copy(
        source_path: @source, target_path: target, required_packages: %w[ace-git-github ace-lab]
      )
    end
    assert_match(/missing required package: ace-lab/, error.message)
  end

  private

  def invalid_manifest
    Ace::Test::EndToEndRunner::Molecules::ReleaseManifest::Invalid
  end

  def load_manifest
    Ace::Test::EndToEndRunner::Molecules::ReleaseManifest.load_validated(@source)
  end

  def write_manifest(payload)
    File.write(@source, payload.is_a?(String) ? payload : JSON.generate(payload))
    @source
  end

  def valid_manifest(overrides = {})
    {
      "schema_version" => 1,
      "source_sha" => "a" * 40,
      "packages" => [
        {"name" => "ace-git-github", "artifact_version" => "0.2.0", "source_sha" => "b" * 40},
        {
          "name" => "ace-test-runner",
          "artifact_version" => "0.27.1",
          "source_sha" => "c" * 40,
          "supersedes" => ["0.27.0"]
        }
      ]
    }.merge(overrides)
  end
end

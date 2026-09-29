# frozen_string_literal: true

require_relative "../test_helper"
require_relative "../e2e/TS-MONO-001-rubygems-install/install_receipt"
require "json"
require "tmpdir"

class InstallReceiptTest < AceMonorepoE2eTestCase
  def setup
    @tmpdir = Dir.mktmpdir
    @manifest_path = File.join(@tmpdir, "release-manifest.json")
    write_manifest
  end

  def teardown
    FileUtils.remove_entry(@tmpdir) if @tmpdir && Dir.exist?(@tmpdir)
  end

  def test_parse_lockfile_reads_registry_packages_and_ignores_dependencies
    lockfile = write_lockfile("normal", <<~LOCK)
      GEM
        remote: https://rubygems.org/
        specs:
          ace-b36ts (0.14.2)
            ace-support-core (~> 0.30)
          ace-git-github (0.2.0)
            addressable (~> 2.9)

      PLATFORMS
        arm64-darwin-24

      DEPENDENCIES
        ace-b36ts!

      BUNDLED WITH
         2.5.23
    LOCK

    parsed = InstallReceipt.parse_lockfile(lockfile)

    assert_equal "0.2.0", parsed["packages"]["ace-git-github"]
    assert_equal "0.14.2", parsed["packages"]["ace-b36ts"]
    assert_equal %w[GEM], parsed["sections"].keys
  end

  def test_parse_lockfile_detects_path_and_git_sections
    lockfile = write_lockfile("normal", <<~LOCK)
      GEM
        remote: https://rubygems.org/
        specs:
          ace-git-github (0.2.0)

      PATH
        remote: /Users/mc/Ps/ace/ace-git
        specs:
          ace-git (0.25.0)
    LOCK

    parsed = InstallReceipt.parse_lockfile(lockfile)

    assert_equal %w[GEM PATH], parsed["sections"].keys
  end

  def test_write_consumer_gemfile_pins_exact_manifest_version_without_provider
    write_manifest
    out = File.join(@tmpdir, "consumer", "ace-bundle", "Gemfile")

    InstallReceipt.write_consumer_gemfile(manifest_path: @manifest_path, name: "ace-bundle", out_path: out)

    content = File.read(out)
    assert_includes content, "gem 'ace-bundle', '0.44.2'"
    refute_includes content, "ace-git-github"
  end

  def test_write_consumer_gemfile_rejects_unknown_package
    write_manifest
    out = File.join(@tmpdir, "consumer", "ace-unknown", "Gemfile")

    error = assert_raises(ArgumentError) do
      InstallReceipt.write_consumer_gemfile(manifest_path: @manifest_path, name: "ace-unknown", out_path: out)
    end
    assert_match(/no package ace-unknown/, error.message)
  end

  def test_verify_accepts_graph_matching_manifest_exactly
    fixture = build_complete_fixture

    verdict = InstallReceipt.verify(
      manifest_path: @manifest_path,
      mode_dirs: {"normal" => fixture[:normal], "full_index" => fixture[:full_index]}
    )

    assert_equal "pass", verdict["acceptance"], verdict["findings"].inspect
    assert_empty verdict["findings"]
    assert_equal 0, verdict["modes"]["normal"]["exit"]
    assert verdict["consumer_edges"]["normal"]["ace-bundle"]["ok"]
    assert verdict["consumer_edges"]["full_index"]["ace-task"]["ok"]
  end

  def test_verify_rejects_stale_but_compatible_versions
    fixture = build_complete_fixture
    rewrite_lockfile(fixture[:normal], "ace-git-github" => "0.1.2")
    rewrite_receipt(fixture[:normal], "ace-git-github" => {"version" => "0.1.2"})

    verdict = InstallReceipt.verify(
      manifest_path: @manifest_path,
      mode_dirs: {"normal" => fixture[:normal], "full_index" => fixture[:full_index]}
    )

    assert_equal "fail", verdict["acceptance"]
    assert(verdict["findings"].any? { |finding| finding.include?("ace-git-github lockfile resolved 0.1.2") },
      verdict["findings"].inspect)
    assert(verdict["findings"].any? { |finding| finding.include?("ace-git-github activated 0.1.2") },
      verdict["findings"].inspect)
  end

  def test_verify_rejects_missing_manifest_entries
    fixture = build_complete_fixture
    rewrite_lockfile(fixture[:normal], "ace-overseer" => nil)
    rewrite_receipt(fixture[:normal], "ace-overseer" => nil)

    verdict = InstallReceipt.verify(
      manifest_path: @manifest_path,
      mode_dirs: {"normal" => fixture[:normal], "full_index" => fixture[:full_index]}
    )

    assert_equal "fail", verdict["acceptance"]
    assert(verdict["findings"].any? { |finding| finding.include?("ace-overseer missing from lockfile") },
      verdict["findings"].inspect)
  end

  def test_verify_rejects_source_and_path_dependencies
    fixture = build_complete_fixture
    append_to_lockfile(fixture[:normal], <<~LOCK)
      PATH
        remote: /Users/mc/Ps/ace/ace-git
        specs:
          ace-git (0.25.0)
    LOCK

    verdict = InstallReceipt.verify(
      manifest_path: @manifest_path,
      mode_dirs: {"normal" => fixture[:normal], "full_index" => fixture[:full_index]}
    )

    assert_equal "fail", verdict["acceptance"]
    assert(verdict["findings"].any? { |finding| finding.include?("PATH sources") }, verdict["findings"].inspect)
  end

  def test_verify_rejects_activated_specs_outside_isolation
    fixture = build_complete_fixture
    rewrite_receipt(fixture[:full_index], "ace-git" => {"version" => "0.25.0", "path" => "/Users/mc/Ps/ace/ace-git"})

    verdict = InstallReceipt.verify(
      manifest_path: @manifest_path,
      mode_dirs: {"normal" => fixture[:normal], "full_index" => fixture[:full_index]}
    )

    assert_equal "fail", verdict["acceptance"]
    assert(verdict["findings"].any? { |finding| finding.include?("outside the isolated gem directories") },
      verdict["findings"].inspect)
  end

  def test_verify_rejects_lockfile_and_activated_disagreement
    fixture = build_complete_fixture
    rewrite_receipt(fixture[:normal], "ace-test" => {"version" => "0.7.3"})

    verdict = InstallReceipt.verify(
      manifest_path: @manifest_path,
      mode_dirs: {"normal" => fixture[:normal], "full_index" => fixture[:full_index]}
    )

    assert_equal "fail", verdict["acceptance"]
    assert(verdict["findings"].any? { |finding| finding.include?("ace-test activated 0.7.3") },
      verdict["findings"].inspect)
  end

  def test_verify_rejects_superseded_versions_still_present
    fixture = build_complete_fixture
    rewrite_lockfile(fixture[:full_index], "ace-test-runner" => "0.27.0")
    rewrite_receipt(fixture[:full_index], "ace-test-runner" => {"version" => "0.27.0"})

    verdict = InstallReceipt.verify(
      manifest_path: @manifest_path,
      mode_dirs: {"normal" => fixture[:normal], "full_index" => fixture[:full_index]}
    )

    assert_equal "fail", verdict["acceptance"]
    assert(verdict["findings"].any? { |finding| finding.include?("superseded by 0.27.1 but still present") },
      verdict["findings"].inspect)
  end

  def test_verify_requires_consumer_dependency_edge_without_direct_provider_entry
    fixture = build_complete_fixture
    rewrite_consumer_lockfile(fixture[:normal], "ace-review", "ace-git-github" => nil)

    verdict = InstallReceipt.verify(
      manifest_path: @manifest_path,
      mode_dirs: {"normal" => fixture[:normal], "full_index" => fixture[:full_index]}
    )

    assert_equal "fail", verdict["acceptance"]
    assert(verdict["findings"].any? { |finding| finding.include?("normal consumer ace-review") && finding.include?("not reached") },
      verdict["findings"].inspect)
  end

  def test_verify_rejects_consumer_gemfile_with_direct_provider_entry
    fixture = build_complete_fixture
    gemfile = File.join(fixture[:full_index], "consumer", "ace-task", "Gemfile")
    File.write(gemfile, File.read(gemfile) + "gem 'ace-git-github', '0.2.0'\n")

    verdict = InstallReceipt.verify(
      manifest_path: @manifest_path,
      mode_dirs: {"normal" => fixture[:normal], "full_index" => fixture[:full_index]}
    )

    assert_equal "fail", verdict["acceptance"]
    assert(verdict["findings"].any? { |finding| finding.include?("must not reference ace-git-github directly") },
      verdict["findings"].inspect)
  end

  def test_finalize_rejects_wrapper_error_despite_zero_bundle_exits
    fixture = build_complete_fixture
    report_dir = File.join(@tmpdir, "reports")
    FileUtils.mkdir_p(report_dir)
    File.write(File.join(report_dir, "metadata.yml"), <<~YAML)
      status: error
      uncertain_execution: true
    YAML

    verdict = InstallReceipt.finalize(
      manifest_path: @manifest_path,
      mode_dirs: {"normal" => fixture[:normal], "full_index" => fixture[:full_index]},
      pipeline_report_dir: report_dir
    )

    assert_equal "pass", verdict["acceptance"]
    assert_equal "fail", verdict["final"]
    assert(verdict["findings"].any? { |finding| finding.include?("pipeline status is") },
      verdict["findings"].inspect)
    assert(verdict["findings"].any? { |finding| finding.include?("uncertain_execution") },
      verdict["findings"].inspect)
  end

  def test_finalize_passes_with_completed_pipeline_and_accepted_graph
    fixture = build_complete_fixture
    report_dir = File.join(@tmpdir, "reports")
    FileUtils.mkdir_p(report_dir)
    File.write(File.join(report_dir, "metadata.yml"), "status: pass\n")

    verdict = InstallReceipt.finalize(
      manifest_path: @manifest_path,
      mode_dirs: {"normal" => fixture[:normal], "full_index" => fixture[:full_index]},
      pipeline_report_dir: report_dir
    )

    assert_equal "pass", verdict["final"], verdict["findings"].inspect
    assert_equal "pass", verdict["pipeline_completion"]["status"]
  end

  def test_finalize_requires_pipeline_metadata
    fixture = build_complete_fixture

    verdict = InstallReceipt.finalize(
      manifest_path: @manifest_path,
      mode_dirs: {"normal" => fixture[:normal], "full_index" => fixture[:full_index]},
      pipeline_report_dir: File.join(@tmpdir, "absent-reports")
    )

    assert_equal "fail", verdict["final"]
    assert(verdict["findings"].any? { |finding| finding.include?("metadata.yml is missing") },
      verdict["findings"].inspect)
  end

  private

  def write_manifest
    File.write(@manifest_path, JSON.pretty_generate(
      "schema_version" => 1,
      "source_sha" => "a" * 40,
      "packages" => [
        {"name" => "ace-git-github", "artifact_version" => "0.2.0", "source_sha" => "b" * 40},
        {"name" => "ace-bundle", "artifact_version" => "0.44.2", "source_sha" => "b" * 40,
         "supersedes" => ["0.44.1"]},
        {"name" => "ace-review", "artifact_version" => "0.56.1", "source_sha" => "b" * 40},
        {"name" => "ace-task", "artifact_version" => "0.38.1", "source_sha" => "b" * 40},
        {"name" => "ace-git", "artifact_version" => "0.25.0", "source_sha" => "b" * 40},
        {"name" => "ace-test", "artifact_version" => "0.7.4", "source_sha" => "b" * 40},
        {"name" => "ace-test-runner", "artifact_version" => "0.27.1", "source_sha" => "b" * 40,
         "supersedes" => ["0.27.0"]},
        {"name" => "ace-overseer", "artifact_version" => "0.17.0", "source_sha" => "b" * 40}
      ]
    ))
  end

  MANIFEST_PACKAGES = {
    "ace-git-github" => "0.2.0",
    "ace-bundle" => "0.44.2",
    "ace-review" => "0.56.1",
    "ace-task" => "0.38.1",
    "ace-git" => "0.25.0",
    "ace-test" => "0.7.4",
    "ace-test-runner" => "0.27.1",
    "ace-overseer" => "0.17.0"
  }.freeze

  def build_complete_fixture
    normal = File.join(@tmpdir, "normal-case")
    full_index = File.join(@tmpdir, "full-index-case")
    [normal, full_index].each do |dir|
      FileUtils.mkdir_p([File.join(dir, ".bundle"), File.join(dir, ".gem")])
      write_lockfile(dir, lockfile_content)
      File.write(File.join(dir, dir == full_index ? "fullindex.exit" : "install.exit"), "0\n")
      File.write(File.join(dir, "install-receipt.json"), JSON.pretty_generate(receipt_content(dir)))
      %w[ace-bundle ace-review ace-task].each do |consumer|
        build_consumer(dir, consumer)
      end
    end
    {normal: normal, full_index: full_index}
  end

  def build_consumer(mode_dir, consumer)
    root = File.join(mode_dir, "consumer", consumer)
    FileUtils.mkdir_p([File.join(root, ".bundle"), File.join(root, ".gem")])
    File.write(File.join(root, "Gemfile"), <<~GEMFILE)
      source 'https://rubygems.org'

      gem '#{consumer}', '#{MANIFEST_PACKAGES[consumer]}'
    GEMFILE
    write_consumer_lockfile(root, consumer, "ace-git-github" => "0.2.0")
    File.write(File.join(root, "install.exit"), "0\n")
    File.write(File.join(root, "install-receipt.json"), JSON.pretty_generate({
      "ace-git-github" => {"version" => "0.2.0", "path" => File.join(root, ".bundle", "gems", "ace-git-github-0.2.0")},
      consumer => {"version" => MANIFEST_PACKAGES[consumer], "path" => File.join(root, ".bundle", "gems", "#{consumer}-#{MANIFEST_PACKAGES[consumer]}")}
    }))
  end

  def lockfile_content
    entries = MANIFEST_PACKAGES.map { |name, version| "    #{name} (#{version})" }.join("\n")
    <<~LOCK
      GEM
        remote: https://rubygems.org/
        specs:
      #{entries}

      PLATFORMS
        arm64-darwin-24

      DEPENDENCIES
        ace-bundle!

      BUNDLED WITH
         2.5.23
    LOCK
  end

  def write_lockfile(dir, content)
    FileUtils.mkdir_p(dir)
    File.write(File.join(dir, "Gemfile.lock"), content)
    File.join(dir, "Gemfile.lock")
  end

  def rewrite_lockfile(dir, overrides)
    path = File.join(dir, "Gemfile.lock")
    content = File.read(path)
    overrides.each do |name, version|
      if version.nil?
        content = content.gsub(/^    #{Regexp.escape(name)} \([^\n]+\)\n/, "")
      else
        content = content.sub(/    #{Regexp.escape(name)} \([^\n]+\)/, "    #{name} (#{version})")
      end
    end
    File.write(path, content)
  end

  def append_to_lockfile(dir, extra)
    path = File.join(dir, "Gemfile.lock")
    File.write(path, File.read(path) + "\n" + extra)
  end

  def receipt_content(dir)
    MANIFEST_PACKAGES.to_h do |name, version|
      [name, {"version" => version, "path" => File.join(dir, ".bundle", "gems", "#{name}-#{version}")}]
    end
  end

  def rewrite_receipt(dir, overrides)
    path = File.join(dir, "install-receipt.json")
    receipt = JSON.parse(File.read(path))
    overrides.each do |name, data|
      if data.nil?
        receipt.delete(name)
      else
        receipt[name].merge!(data)
      end
    end
    File.write(path, JSON.pretty_generate(receipt))
  end

  def write_consumer_lockfile(root, consumer, provider)
    entries = ["    #{consumer} (#{MANIFEST_PACKAGES[consumer]})"]
    entries << "    ace-git-github (#{provider["ace-git-github"]})" if provider["ace-git-github"]
    File.write(File.join(root, "Gemfile.lock"), <<~LOCK)
      GEM
        remote: https://rubygems.org/
        specs:
      #{entries.join("\n")}

      DEPENDENCIES
        #{consumer}!

      BUNDLED WITH
         2.5.23
    LOCK
  end

  def rewrite_consumer_lockfile(mode_dir, consumer, overrides)
    path = File.join(mode_dir, "consumer", consumer, "Gemfile.lock")
    content = File.read(path)
    overrides.each do |name, version|
      if version.nil?
        content = content.gsub(/^    #{Regexp.escape(name)} \([^\n]+\)\n/, "")
      else
        content = content.sub(/    #{Regexp.escape(name)} \([^\n]+\)/, "    #{name} (#{version})")
      end
    end
    File.write(path, content)
  end
end

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
    lockfile = write_lockfile(File.join(@tmpdir, "normal"), <<~LOCK)
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
    lockfile = write_lockfile(File.join(@tmpdir, "normal"), <<~LOCK)
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

  def test_verify_rejects_failed_consumer_install
    fixture = build_complete_fixture
    File.write(File.join(fixture[:normal], "consumer", "ace-bundle", "install.exit"), "1\n")

    verdict = InstallReceipt.verify(
      manifest_path: @manifest_path,
      mode_dirs: {"normal" => fixture[:normal], "full_index" => fixture[:full_index]}
    )

    assert_equal "fail", verdict["acceptance"]
    assert(verdict["findings"].any? { |finding| finding.include?("normal consumer ace-bundle") && finding.include?("did not succeed (exit 1)") },
      verdict["findings"].inspect)
  end

  def test_verify_rejects_failed_mode_install_despite_present_receipts
    fixture = build_complete_fixture
    File.write(File.join(fixture[:normal], "install.exit"), "1\n")

    verdict = InstallReceipt.verify(
      manifest_path: @manifest_path,
      mode_dirs: {"normal" => fixture[:normal], "full_index" => fixture[:full_index]}
    )

    assert_equal "fail", verdict["acceptance"]
    assert(verdict["findings"].any? { |finding| finding.start_with?("normal: ") && finding.include?("install did not succeed (exit 1)") },
      verdict["findings"].inspect)
  end

  def test_verify_rejects_stale_activated_provider_in_consumer_edge
    fixture = build_complete_fixture
    root = File.join(fixture[:normal], "consumer", "ace-review")
    receipt = JSON.parse(File.read(File.join(root, "install-receipt.json")))
    receipt["packages"]["ace-git-github"]["version"] = "0.1.2"
    File.write(File.join(root, "install-receipt.json"), JSON.pretty_generate(receipt))

    verdict = InstallReceipt.verify(
      manifest_path: @manifest_path,
      mode_dirs: {"normal" => fixture[:normal], "full_index" => fixture[:full_index]}
    )

    assert_equal "fail", verdict["acceptance"]
    assert(verdict["findings"].any? { |finding| finding.include?("normal consumer ace-review") && finding.include?("ace-git-github activated 0.1.2") },
      verdict["findings"].inspect)
  end

  def test_verify_rejects_consumer_receipt_without_packages_object
    fixture = build_complete_fixture
    root = File.join(fixture[:full_index], "consumer", "ace-task")
    File.write(File.join(root, "install-receipt.json"), JSON.pretty_generate({"ace-git-github" => {"version" => "0.2.0"}}))

    verdict = InstallReceipt.verify(
      manifest_path: @manifest_path,
      mode_dirs: {"normal" => fixture[:normal], "full_index" => fixture[:full_index]}
    )

    assert_equal "fail", verdict["acceptance"]
    assert(verdict["findings"].any? { |finding| finding.include?("full_index consumer ace-task") && finding.include?("no packages object") },
      verdict["findings"].inspect)
  end

  def test_verify_rejects_consumer_gemfile_with_extra_gem_entries
    fixture = build_complete_fixture
    gemfile = File.join(fixture[:normal], "consumer", "ace-bundle", "Gemfile")
    File.write(gemfile, "source 'https://rubygems.org'\n\ngem 'ace-bundle', '0.44.2'\ngem 'ace-git', '0.25.0'\n")

    verdict = InstallReceipt.verify(
      manifest_path: @manifest_path,
      mode_dirs: {"normal" => fixture[:normal], "full_index" => fixture[:full_index]}
    )

    assert_equal "fail", verdict["acceptance"]
    assert(verdict["findings"].any? { |finding| finding.include?("exactly the consumer ace-bundle as its only gem") },
      verdict["findings"].inspect)
  end

  def test_verify_rejects_consumer_lockfile_without_published_provider_edge
    fixture = build_complete_fixture
    path = File.join(fixture[:full_index], "consumer", "ace-task", "Gemfile.lock")
    content = File.read(path)
    content = content.sub("      ace-git-github (~> 0.2)\n", "")
    File.write(path, content)

    verdict = InstallReceipt.verify(
      manifest_path: @manifest_path,
      mode_dirs: {"normal" => fixture[:normal], "full_index" => fixture[:full_index]}
    )

    assert_equal "fail", verdict["acceptance"]
    assert(verdict["findings"].any? { |finding| finding.include?("full_index consumer ace-task") && finding.include?("does not declare ace-git-github") },
      verdict["findings"].inspect)
  end

  def test_verify_rejects_receipts_missing_gem_paths
    fixture = build_complete_fixture
    rewrite_receipt(fixture[:full_index], "ace-git" => {"path" => ""})

    verdict = InstallReceipt.verify(
      manifest_path: @manifest_path,
      mode_dirs: {"normal" => fixture[:normal], "full_index" => fixture[:full_index]}
    )

    assert_equal "fail", verdict["acceptance"]
    assert(verdict["findings"].any? { |finding| finding.include?("full_index: ace-git activated receipt records no gem path") },
      verdict["findings"].inspect)
  end

  def test_finalize_requires_pipeline_metadata
    fixture = build_complete_fixture
    results_root = write_results_root(fixture)

    verdict = InstallReceipt.finalize(
      manifest_path: @manifest_path,
      mode_dirs: {"normal" => fixture[:normal], "full_index" => fixture[:full_index]},
      pipeline_report_dir: File.join(@tmpdir, "absent-reports"),
      results_root: results_root,
      source_manifest: @manifest_path
    )

    assert_equal "fail", verdict["final"]
    assert(verdict["findings"].any? { |finding| finding.include?("metadata.yml is missing") },
      verdict["findings"].inspect)
  end

  def test_verify_rejects_consumer_gemfile_with_local_source
    fixture = build_complete_fixture
    gemfile = File.join(fixture[:normal], "consumer", "ace-bundle", "Gemfile")
    File.write(gemfile, "source 'https://rubygems.org'\n\ngem 'ace-bundle', path: '/Users/mc/Ps/ace/ace-bundle'\n")

    verdict = InstallReceipt.verify(
      manifest_path: @manifest_path,
      mode_dirs: {"normal" => fixture[:normal], "full_index" => fixture[:full_index]}
    )

    assert_equal "fail", verdict["acceptance"]
    assert(verdict["findings"].any? { |finding| finding.include?("normal consumer ace-bundle") && finding.include?("not path/git sources") },
      verdict["findings"].inspect)
  end

  def test_verify_rejects_consumer_lockfile_with_path_section
    fixture = build_complete_fixture
    lockfile = File.join(fixture[:full_index], "consumer", "ace-review", "Gemfile.lock")
    File.write(lockfile, File.read(lockfile) + "\nPATH\n  remote: /Users/mc/Ps/ace/ace-review\n  specs:\n    ace-review (0.56.1)\n")

    verdict = InstallReceipt.verify(
      manifest_path: @manifest_path,
      mode_dirs: {"normal" => fixture[:normal], "full_index" => fixture[:full_index]}
    )

    assert_equal "fail", verdict["acceptance"]
    assert(verdict["findings"].any? { |finding| finding.include?("full_index consumer ace-review") && finding.include?("PATH sources") },
      verdict["findings"].inspect)
  end


def test_verify_rejects_superseded_version_in_duplicate_lockfile_entries
  fixture = build_complete_fixture
  path = File.join(fixture[:normal], "Gemfile.lock")
  content = File.read(path)
  content.sub!(/^    ace-test-runner \(0\.27\.1\)\n/, "    ace-test-runner (0.27.1)\n    ace-test-runner (0.27.0)\n")
  File.write(path, content)

  verdict = InstallReceipt.verify(
    manifest_path: @manifest_path,
    mode_dirs: {"normal" => fixture[:normal], "full_index" => fixture[:full_index]}
  )

  assert_equal "fail", verdict["acceptance"]
  assert(verdict["findings"].any? { |finding| finding.include?("ace-test-runner 0.27.0 is superseded by 0.27.1 but still present") },
    verdict["findings"].inspect)
end

def test_verify_records_finding_for_malformed_receipt_entries
  fixture = build_complete_fixture
  receipt_path = File.join(fixture[:normal], "install-receipt.json")
  receipt = JSON.parse(File.read(receipt_path))
  receipt["packages"]["ace-git"] = "0.25.0"
  File.write(receipt_path, JSON.pretty_generate(receipt))

  verdict = InstallReceipt.verify(
    manifest_path: @manifest_path,
    mode_dirs: {"normal" => fixture[:normal], "full_index" => fixture[:full_index]}
  )

  assert_equal "fail", verdict["acceptance"]
  assert(verdict["findings"].any? { |finding| finding.include?("activated receipt entry ace-git must be an object") },
    verdict["findings"].inspect)
end

def test_finalize_reports_findings_for_malformed_pipeline_metadata
  fixture = build_complete_fixture
  report_dir = File.join(@tmpdir, "reports")
  results_root = write_results_root(fixture)
  FileUtils.mkdir_p(report_dir)
  File.write(File.join(report_dir, "metadata.yml"), "{{{ not yaml")

  verdict = InstallReceipt.finalize(
    manifest_path: @manifest_path,
    mode_dirs: {"normal" => fixture[:normal], "full_index" => fixture[:full_index]},
    pipeline_report_dir: report_dir,
    results_root: results_root,
    source_manifest: @manifest_path
  )

  assert_equal "fail", verdict["final"]
  assert(verdict["findings"].any? { |finding| finding.include?("not parseable YAML") }, verdict["findings"].inspect)
end

def test_finalize_reports_findings_for_non_mapping_pipeline_metadata
  fixture = build_complete_fixture
  report_dir = File.join(@tmpdir, "reports")
  results_root = write_results_root(fixture)
  FileUtils.mkdir_p(report_dir)
  File.write(File.join(report_dir, "metadata.yml"), "- just
- a list
")

  verdict = InstallReceipt.finalize(
    manifest_path: @manifest_path,
    mode_dirs: {"normal" => fixture[:normal], "full_index" => fixture[:full_index]},
    pipeline_report_dir: report_dir,
    results_root: results_root,
    source_manifest: @manifest_path
  )

  assert_equal "fail", verdict["final"]
  assert(verdict["findings"].any? { |finding| finding.include?("not a mapping") }, verdict["findings"].inspect)
end

def test_finalize_reports_findings_for_malformed_acceptance_artifact
  fixture = build_complete_fixture
  report_dir = File.join(@tmpdir, "reports")
  results_root = write_results_root(fixture)
  tc04 = File.join(results_root, "results", "tc", "04")
  File.write(File.join(tc04, "exact-version-acceptance.json"), "{not json")
  FileUtils.mkdir_p(report_dir)
  File.write(File.join(report_dir, "metadata.yml"), "run-id: reports\ntest-id: TS-MONO-001\nstatus: pass\n")


  verdict = InstallReceipt.finalize(
    manifest_path: @manifest_path,
    mode_dirs: {"normal" => fixture[:normal], "full_index" => fixture[:full_index]},
    pipeline_report_dir: report_dir,
    results_root: results_root,
    source_manifest: @manifest_path
  )

  assert_equal "fail", verdict["final"]
  assert(verdict["findings"].any? { |finding| finding.include?("not valid JSON") }, verdict["findings"].inspect)
end


def test_verify_rejects_non_rubygems_remote
  fixture = build_complete_fixture
  path = File.join(fixture[:normal], "Gemfile.lock")
  content = File.read(path).sub("https://rubygems.org/", "https://mirror.example.com/")
  File.write(path, content)

  verdict = InstallReceipt.verify(
    manifest_path: @manifest_path,
    mode_dirs: {"normal" => fixture[:normal], "full_index" => fixture[:full_index]}
  )

  assert_equal "fail", verdict["acceptance"]
  assert(verdict["findings"].any? { |finding| finding.include?("non-rubygems.org remotes") },
    verdict["findings"].inspect)
end

def test_verify_rejects_lockfile_receipt_disagreement
  fixture = build_complete_fixture
  receipt_path = File.join(fixture[:full_index], "lockfile-receipt.json")
  receipt = JSON.parse(File.read(receipt_path))
  receipt["packages"]["ace-overseer"] = "0.16.0"
  File.write(receipt_path, JSON.pretty_generate(receipt))

  verdict = InstallReceipt.verify(
    manifest_path: @manifest_path,
    mode_dirs: {"normal" => fixture[:normal], "full_index" => fixture[:full_index]}
  )

  assert_equal "fail", verdict["acceptance"]
  assert(verdict["findings"].any? { |finding| finding.include?("lockfile receipt records ace-overseer") },
    verdict["findings"].inspect)
end

def test_finalize_rejects_stale_pipeline_report
  fixture = build_complete_fixture
  report_dir = File.join(@tmpdir, "reports")
  results_root = write_results_root(fixture)
  FileUtils.mkdir_p(report_dir)
  File.write(File.join(report_dir, "metadata.yml"), "run-id: stale-run-000\ntest-id: TS-MONO-001\nstatus: pass\n")

  verdict = InstallReceipt.finalize(
    manifest_path: @manifest_path,
    mode_dirs: {"normal" => fixture[:normal], "full_index" => fixture[:full_index]},
    pipeline_report_dir: report_dir,
    results_root: results_root,
    source_manifest: @manifest_path
  )

  assert_equal "fail", verdict["final"]
  assert(verdict["findings"].any? { |finding| finding.include?("does not match the current run") },
    verdict["findings"].inspect)
end

def test_finalize_rejects_acceptance_artifact_missing_coverage
  fixture = build_complete_fixture
  report_dir = File.join(@tmpdir, "reports")
  results_root = write_results_root(fixture)
  tc04 = File.join(results_root, "results", "tc", "04")
  File.write(File.join(tc04, "exact-version-acceptance.json"), JSON.pretty_generate(
    "schema_version" => 1,
    "kind" => "exact-version-acceptance",
    "acceptance" => "pass",
    "findings" => []
  ))
  FileUtils.mkdir_p(report_dir)
  File.write(File.join(report_dir, "metadata.yml"), "run-id: reports\ntest-id: TS-MONO-001\nstatus: pass\n")

  verdict = InstallReceipt.finalize(
    manifest_path: @manifest_path,
    mode_dirs: {"normal" => fixture[:normal], "full_index" => fixture[:full_index]},
    pipeline_report_dir: report_dir,
    results_root: results_root,
    source_manifest: @manifest_path
  )

  assert_equal "fail", verdict["final"]
  assert(verdict["findings"].any? { |finding| finding.include?("package_count") }, verdict["findings"].inspect)
  assert(verdict["findings"].any? { |finding| finding.include?("is missing normal package results") }, verdict["findings"].inspect)
  assert(verdict["findings"].any? { |finding| finding.include?("consumer edge for ace-bundle") }, verdict["findings"].inspect)
end

def test_verify_records_finding_for_non_string_receipt_path
  fixture = build_complete_fixture
  receipt_path = File.join(fixture[:normal], "install-receipt.json")
  receipt = JSON.parse(File.read(receipt_path))
  receipt["packages"]["ace-git"]["path"] = {"bad" => true}
  File.write(receipt_path, JSON.pretty_generate(receipt))

  verdict = InstallReceipt.verify(
    manifest_path: @manifest_path,
    mode_dirs: {"normal" => fixture[:normal], "full_index" => fixture[:full_index]}
  )

  assert_equal "fail", verdict["acceptance"]
  assert(verdict["findings"].any? { |finding| finding.include?("path must be a string") },
    verdict["findings"].inspect)
end

  def test_finalize_rejects_wrapper_error_despite_zero_bundle_exits
    fixture = build_complete_fixture
    report_dir = File.join(@tmpdir, "reports")
    results_root = write_results_root(fixture)
    FileUtils.mkdir_p(report_dir)
    File.write(File.join(report_dir, "metadata.yml"), "run-id: reports\nstatus: error\nuncertain_execution: true\n")

    verdict = InstallReceipt.finalize(
      manifest_path: @manifest_path,
      mode_dirs: {"normal" => fixture[:normal], "full_index" => fixture[:full_index]},
      pipeline_report_dir: report_dir,
      results_root: results_root,
      source_manifest: @manifest_path
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
    results_root = write_results_root(fixture)
    FileUtils.mkdir_p(report_dir)
    File.write(File.join(report_dir, "metadata.yml"), "run-id: reports\ntest-id: TS-MONO-001\nstatus: pass\n")


    verdict = InstallReceipt.finalize(
      manifest_path: @manifest_path,
      mode_dirs: {"normal" => fixture[:normal], "full_index" => fixture[:full_index]},
      pipeline_report_dir: report_dir,
      results_root: results_root,
      source_manifest: @manifest_path
    )

    assert_equal "pass", verdict["final"], verdict["findings"].inspect
    assert_equal "pass", verdict["pipeline_completion"]["status"]
    assert_equal "SAFE", verdict["results_reconciliation"]["recorded_classification"]
    assert verdict["manifest_integrity"]["ok"]
  end

  def test_finalize_rejects_tampered_sandbox_manifest_copy
    fixture = build_complete_fixture
    report_dir = File.join(@tmpdir, "reports")
    results_root = write_results_root(fixture)
    FileUtils.mkdir_p(report_dir)
    File.write(File.join(report_dir, "metadata.yml"), "run-id: reports\ntest-id: TS-MONO-001\nstatus: pass\n")


    tampered = File.join(@tmpdir, "source-manifest.json")
    manifest = JSON.parse(File.read(@manifest_path))
    manifest["packages"].delete_at(0)
    File.write(tampered, JSON.pretty_generate(manifest))

    verdict = InstallReceipt.finalize(
      manifest_path: @manifest_path,
      mode_dirs: {"normal" => fixture[:normal], "full_index" => fixture[:full_index]},
      pipeline_report_dir: report_dir,
      results_root: results_root,
      source_manifest: tampered
    )

    assert_equal "fail", verdict["final"]
    assert(verdict["findings"].any? { |finding| finding.include?("sandbox manifest copy does not match") },
      verdict["findings"].inspect)
  end

  def test_finalize_rejects_classification_disagreement
    fixture = build_complete_fixture
    report_dir = File.join(@tmpdir, "reports")
    results_root = write_results_root(fixture, classification: "LAG_DETECTED")
    FileUtils.mkdir_p(report_dir)
    File.write(File.join(report_dir, "metadata.yml"), "run-id: reports\ntest-id: TS-MONO-001\nstatus: pass\n")


    verdict = InstallReceipt.finalize(
      manifest_path: @manifest_path,
      mode_dirs: {"normal" => fixture[:normal], "full_index" => fixture[:full_index]},
      pipeline_report_dir: report_dir,
      results_root: results_root,
      source_manifest: @manifest_path
    )

    assert_equal "fail", verdict["final"]
    assert(verdict["findings"].any? { |finding| finding.include?("recorded classification \"LAG_DETECTED\" disagrees with recomputed \"SAFE\"") },
      verdict["findings"].inspect)
  end

  def test_finalize_rejects_failing_runner_acceptance_artifact
    fixture = build_complete_fixture
    report_dir = File.join(@tmpdir, "reports")
    results_root = write_results_root(fixture, runner_acceptance: "fail")
    FileUtils.mkdir_p(report_dir)
    File.write(File.join(report_dir, "metadata.yml"), "run-id: reports\ntest-id: TS-MONO-001\nstatus: pass\n")


    verdict = InstallReceipt.finalize(
      manifest_path: @manifest_path,
      mode_dirs: {"normal" => fixture[:normal], "full_index" => fixture[:full_index]},
      pipeline_report_dir: report_dir,
      results_root: results_root,
      source_manifest: @manifest_path
    )

    assert_equal "fail", verdict["final"]
    assert(verdict["findings"].any? { |finding| finding.include?("runner-side acceptance \"fail\" is not pass") },
      verdict["findings"].inspect)
  end

  def test_finalize_cli_documented_invocation_exits_zero_when_all_gates_pass
    fixture = build_complete_fixture
    report_dir = File.join(@tmpdir, "reports")
    results_root = write_results_root(fixture)
    FileUtils.mkdir_p(report_dir)
    File.write(File.join(report_dir, "metadata.yml"), "run-id: reports\ntest-id: TS-MONO-001\nstatus: pass\n")

    out_path = File.join(@tmpdir, "evidence", "nested", "installation-acceptance.json")
    script = File.expand_path("../e2e/TS-MONO-001-rubygems-install/install_receipt.rb", __dir__)

    system(RbConfig.ruby, script, "finalize",
      "--manifest", @manifest_path,
      "--source-manifest", @manifest_path,
      "--normal", fixture[:normal],
      "--full-index", fixture[:full_index],
      "--pipeline-report", report_dir,
      "--results-root", results_root,
      "--out", out_path,
      chdir: @tmpdir) or flunk("documented finalize invocation exited non-zero")

    verdict = JSON.parse(File.read(out_path))
    assert_equal "pass", verdict["final"]
  end

  private

def write_results_root(fixture, classification: "SAFE", runner_acceptance: "pass")
  root = File.join(@tmpdir, "results-root")
  tc04 = File.join(root, "results", "tc", "04")
  FileUtils.mkdir_p(tc04)
  File.write(File.join(tc04, "classification.txt"), "#{classification}\n")
  File.write(File.join(tc04, "exact-version-acceptance.json"), JSON.pretty_generate(
    "schema_version" => 1,
    "kind" => "exact-version-acceptance",
    "manifest" => {"path" => @manifest_path, "source_sha" => "a" * 40, "package_count" => MANIFEST_PACKAGES.size},
    "modes" => %w[normal full_index].to_h do |mode|
      [mode, {
        "exit" => 0,
        "packages" => MANIFEST_PACKAGES.keys.to_h { |name| [name, {"manifest_version" => MANIFEST_PACKAGES[name], "ok" => true, "findings" => []}] },
        "findings" => []
      }]
    end,
    "consumer_edges" => %w[normal full_index].to_h do |mode|
      [mode, %w[ace-bundle ace-review ace-task].to_h { |consumer| [consumer, {"ok" => true, "findings" => []}] }]
    end,
    "acceptance" => runner_acceptance,
    "findings" => runner_acceptance == "pass" ? [] : ["fixture finding"]
  ))
  root
end

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
      File.write(File.join(dir, "lockfile-receipt.json"), JSON.pretty_generate({
        "kind" => "lockfile-receipt",
        "packages" => MANIFEST_PACKAGES
      }))
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
      "kind" => "activated-receipt",
      "packages" => {
        "ace-git-github" => {"version" => "0.2.0", "path" => File.join(root, ".bundle", "gems", "ace-git-github-0.2.0")},
        consumer => {"version" => MANIFEST_PACKAGES[consumer], "path" => File.join(root, ".bundle", "gems", "#{consumer}-#{MANIFEST_PACKAGES[consumer]}")}
      }
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
    {
      "kind" => "activated-receipt",
      "packages" => MANIFEST_PACKAGES.to_h do |name, version|
        [name, {"version" => version, "path" => File.join(dir, ".bundle", "gems", "#{name}-#{version}")}]
      end
    }
  end

  def rewrite_receipt(dir, overrides)
    path = File.join(dir, "install-receipt.json")
    receipt = JSON.parse(File.read(path))
    overrides.each do |name, data|
      if data.nil?
        receipt["packages"].delete(name)
      else
        receipt["packages"][name].merge!(data)
      end
    end
    File.write(path, JSON.pretty_generate(receipt))
  end

  def write_consumer_lockfile(root, consumer, provider)
    entries = ["    #{consumer} (#{MANIFEST_PACKAGES[consumer]})", "      ace-git (~> 0.24)"]
    entries << "      ace-git-github (~> 0.2)" if provider["ace-git-github"]
    provider_line = provider["ace-git-github"] ? "    ace-git-github (#{provider["ace-git-github"]})" : nil
    spec_lines = [entries.join("\n"), provider_line].compact.join("\n")
    File.write(File.join(root, "Gemfile.lock"), <<~LOCK)
      GEM
        remote: https://rubygems.org/
        specs:
      #{spec_lines}

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

class InstallReceiptRunnerContractTest < AceMonorepoE2eTestCase
  SCENARIO_DIR = File.expand_path("../e2e/TS-MONO-001-rubygems-install", __dir__)

  def test_consumer_bundle_uses_absolute_bundler_paths
    %w[TC-002-sandbox-install TC-003-fullindex-fallback].each do |tc|
      content = File.read(File.join(SCENARIO_DIR, "#{tc}.runner.md"))
      assert_includes content, 'consumer_dir="$PWD/$1"',
        "#{tc} consumer_bundle must anchor paths at the sandbox root"
      ["BUNDLE_GEMFILE", "BUNDLE_APP_CONFIG", "BUNDLE_PATH", "BUNDLE_USER_HOME",
        "BUNDLE_USER_CACHE", "BUNDLE_USER_CONFIG", "GEM_HOME", "GEM_PATH"].each do |var|
        assert_match(%r{#{var}="\$consumer_dir/}, content,
          "#{tc} consumer_bundle #{var} must use the absolute consumer dir (relative paths double-nest under the Gemfile dir)")
      end
    end
  end
end

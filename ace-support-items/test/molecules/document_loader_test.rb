# frozen_string_literal: true

require "test_helper"
require "tmpdir"

class DocumentLoaderTest < AceSupportItemsTestCase
  DL = Ace::Support::Items::Molecules::DocumentLoader

  def setup
    @tmpdir = Dir.mktmpdir("items-docloader-test")
  end

  def teardown
    FileUtils.rm_rf(@tmpdir)
  end

  def test_load_returns_loaded_document
    idea_dir = create_doc_fixture("8ppq7w-dark-mode", title: "Dark mode", status: "pending")

    doc = DL.load(idea_dir, file_pattern: "*.idea.s.md", spec_extension: ".idea.s.md")

    refute_nil doc
    assert_instance_of Ace::Support::Items::Models::LoadedDocument, doc
    assert_equal "Dark mode", doc.title
    assert_equal "pending", doc.frontmatter["status"]
    assert_includes doc.body, "# Dark mode"
  end

  def test_load_returns_nil_for_nonexistent_dir
    result = DL.load("/nonexistent", file_pattern: "*.idea.s.md", spec_extension: ".idea.s.md")
    assert_nil result
  end

  def test_load_returns_nil_without_spec_file
    empty_dir = File.join(@tmpdir, "8ppq7w-empty")
    FileUtils.mkdir_p(empty_dir)

    result = DL.load(empty_dir, file_pattern: "*.idea.s.md", spec_extension: ".idea.s.md")
    assert_nil result
  end

  def test_load_enumerates_attachments
    idea_dir = create_doc_fixture("8ppq7w-with-files", title: "Test")
    File.write(File.join(idea_dir, "screenshot.png"), "fake")
    File.write(File.join(idea_dir, "notes.txt"), "notes")

    doc = DL.load(idea_dir, file_pattern: "*.idea.s.md", spec_extension: ".idea.s.md")

    assert_includes doc.attachments, "screenshot.png"
    assert_includes doc.attachments, "notes.txt"
    refute doc.attachments.any? { |a| a.end_with?(".idea.s.md") }
  end

  def test_load_excludes_hidden_files_from_attachments
    idea_dir = create_doc_fixture("8ppq7w-hidden", title: "Test")
    File.write(File.join(idea_dir, ".DS_Store"), "hidden")

    doc = DL.load(idea_dir, file_pattern: "*.idea.s.md", spec_extension: ".idea.s.md")

    refute_includes doc.attachments, ".DS_Store"
  end

  def test_load_extracts_title_from_heading
    idea_dir = create_doc_fixture("8ppq7w-heading", body_title: "Heading Title")

    doc = DL.load(idea_dir, file_pattern: "*.idea.s.md", spec_extension: ".idea.s.md")

    assert_equal "Heading Title", doc.title
  end

  def test_load_falls_back_to_folder_name_for_title
    idea_dir = File.join(@tmpdir, "8ppq7w-fallback")
    FileUtils.mkdir_p(idea_dir)
    File.write(File.join(idea_dir, "8ppq7w-fallback.idea.s.md"), "---\nstatus: pending\n---\n\nNo heading here.")

    doc = DL.load(idea_dir, file_pattern: "*.idea.s.md", spec_extension: ".idea.s.md")

    assert_equal "8ppq7w-fallback", doc.title
  end

  def test_from_scan_result
    idea_dir = create_doc_fixture("8ppq7w-scan-result", title: "From scan")

    scan_result = Ace::Support::Items::Models::ScanResult.new(
      id: "8ppq7w",
      slug: "scan-result",
      folder_name: "8ppq7w-scan-result",
      dir_path: idea_dir,
      file_path: Dir.glob(File.join(idea_dir, "*.idea.s.md")).first,
      special_folder: nil
    )

    doc = DL.from_scan_result(scan_result, spec_extension: ".idea.s.md")

    refute_nil doc
    assert_equal "From scan", doc.title
  end

  def test_from_scan_result_returns_nil_for_nil
    assert_nil DL.from_scan_result(nil, spec_extension: ".idea.s.md")
  end

  private

  def create_doc_fixture(folder_name, title: nil, status: "pending", body_title: nil)
    idea_dir = File.join(@tmpdir, folder_name)
    FileUtils.mkdir_p(idea_dir)

    display_title = body_title || title || folder_name
    fm_title = title ? "title: #{title}\n" : ""
    content = <<~CONTENT
      ---
      status: #{status}
      #{fm_title}---

      # #{display_title}

      Test content.
    CONTENT

    File.write(File.join(idea_dir, "#{folder_name}.idea.s.md"), content)
    idea_dir
  end
end

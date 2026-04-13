# frozen_string_literal: true

require "test_helper"

class RetroLoaderTest < AceRetroTestCase
  def test_loads_retro_from_directory
    with_retros_dir do |root|
      retro_dir = create_retro_fixture(root, id: "8ppq7w", slug: "sprint-review",
        type: "standard", tags: ["sprint"])

      loader = Ace::Retro::Molecules::RetroLoader.new
      retro = loader.load(retro_dir, id: "8ppq7w")

      refute_nil retro
      assert_equal "8ppq7w", retro.id
      assert_equal "active", retro.status
      assert_equal "standard", retro.type
      assert_includes retro.tags, "sprint"
    end
  end

  def test_returns_nil_for_nonexistent_directory
    loader = Ace::Retro::Molecules::RetroLoader.new
    result = loader.load("/nonexistent", id: "8ppq7w")
    assert_nil result
  end

  def test_returns_nil_for_directory_without_retro_file
    with_retros_dir do |root|
      empty_dir = File.join(root, "empty")
      FileUtils.mkdir_p(empty_dir)

      loader = Ace::Retro::Molecules::RetroLoader.new
      result = loader.load(empty_dir, id: "8ppq7w")
      assert_nil result
    end
  end

  def test_extracts_id_from_folder_name
    with_retros_dir do |root|
      retro_dir = create_retro_fixture(root, id: "8ppq7w", slug: "sprint-review")

      loader = Ace::Retro::Molecules::RetroLoader.new
      retro = loader.load(retro_dir)

      assert_equal "8ppq7w", retro.id
    end
  end

  def test_lists_folder_contents
    with_retros_dir do |root|
      retro_dir = create_retro_fixture(root, id: "8ppq7w", slug: "sprint-review")
      File.write(File.join(retro_dir, "notes.txt"), "some notes")

      loader = Ace::Retro::Molecules::RetroLoader.new
      retro = loader.load(retro_dir, id: "8ppq7w")

      assert_includes retro.folder_contents, "notes.txt"
    end
  end

  def test_excludes_retro_file_from_folder_contents
    with_retros_dir do |root|
      retro_dir = create_retro_fixture(root, id: "8ppq7w", slug: "sprint-review")

      loader = Ace::Retro::Molecules::RetroLoader.new
      retro = loader.load(retro_dir, id: "8ppq7w")

      retro.folder_contents.each do |f|
        refute f.end_with?(".retro.md"), "Retro file should not appear in folder_contents"
      end
    end
  end

  def test_from_scan_result
    with_retros_dir do |root|
      create_retro_fixture(root, id: "8ppq7w", slug: "sprint-review")

      scanner = Ace::Retro::Molecules::RetroScanner.new(root)
      scan_results = scanner.scan
      assert_equal 1, scan_results.length

      retro = Ace::Retro::Molecules::RetroLoader.from_scan_result(scan_results.first)
      refute_nil retro
      assert_equal "8ppq7w", retro.id
    end
  end
end

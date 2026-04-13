# frozen_string_literal: true

require_relative "../../test_helper"
require "tmpdir"
require "fileutils"

class TapeCreatorTest < AceDemoTestCase
  def setup
    super
    @tmp = Dir.mktmpdir("ace_demo_creator")
    @writer = Ace::Demo::Molecules::TapeWriter.new(cwd: @tmp)
    @creator = Ace::Demo::Organisms::TapeCreator.new(writer: @writer)
  end

  def teardown
    FileUtils.rm_rf(@tmp)
    super
  end

  def test_creates_tape_file
    result = @creator.create(name: "hello", commands: ["echo hello"])

    assert_equal false, result[:dry_run]
    assert result[:path].end_with?("hello.tape.yml")
    assert File.exist?(result[:path])
    assert_includes result[:content], "type: echo hello"
  end

  def test_dry_run_returns_content_without_writing
    result = @creator.create(name: "hello", commands: ["echo hello"], dry_run: true)

    assert_equal true, result[:dry_run]
    assert_nil result[:path]
    assert_includes result[:content], "type: echo hello"

    tape_path = File.join(@tmp, ".ace", "demo", "tapes", "hello.tape.yml")
    refute File.exist?(tape_path)
  end

  def test_passes_metadata_through
    result = @creator.create(
      name: "demo",
      commands: ["make deploy"],
      description: "Deploy flow",
      tags: "ci"
    )

    assert_includes result[:content], "description: Deploy flow"
    assert_includes result[:content], "- ci"
  end

  def test_uses_format_in_output_path
    result = @creator.create(name: "vid", commands: ["echo hi"], format: "mp4")

    assert_includes result[:content], "format: mp4"
  end

  def test_raises_on_conflict_without_force
    @creator.create(name: "conflict", commands: ["echo first"])

    assert_raises(Ace::Demo::TapeAlreadyExistsError) do
      @creator.create(name: "conflict", commands: ["echo second"])
    end
  end

  def test_force_overwrites
    @creator.create(name: "conflict", commands: ["echo first"])
    result = @creator.create(name: "conflict", commands: ["echo second"], force: true)

    assert_includes result[:content], "type: echo second"
  end
end

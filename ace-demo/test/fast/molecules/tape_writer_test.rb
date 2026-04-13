# frozen_string_literal: true

require_relative "../../test_helper"
require "tmpdir"
require "fileutils"

class TapeWriterTest < AceDemoTestCase
  def setup
    super
    @tmp = Dir.mktmpdir("ace_demo_writer")
    @writer = Ace::Demo::Molecules::TapeWriter.new(cwd: @tmp)
  end

  def teardown
    FileUtils.rm_rf(@tmp)
    super
  end

  def test_writes_tape_file
    path = @writer.write(name: "hello", content: "Output hello.gif\n")

    expected = File.join(@tmp, ".ace", "demo", "tapes", "hello.tape")
    assert_equal expected, path
    assert_equal "Output hello.gif\n", File.read(path)
  end

  def test_creates_directories
    path = @writer.write(name: "nested", content: "tape content\n")

    assert File.exist?(path)
    assert File.directory?(File.join(@tmp, ".ace", "demo", "tapes"))
  end

  def test_raises_on_existing_file
    @writer.write(name: "exists", content: "first\n")

    error = assert_raises(Ace::Demo::TapeAlreadyExistsError) do
      @writer.write(name: "exists", content: "second\n")
    end

    assert_includes error.message, "Tape already exists"
    assert_includes error.message, "--force"
  end

  def test_force_overwrites_existing
    @writer.write(name: "exists", content: "first\n")

    path = @writer.write(name: "exists", content: "second\n", force: true)
    assert_equal "second\n", File.read(path)
  end
end

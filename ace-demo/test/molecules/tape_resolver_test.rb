# frozen_string_literal: true

require_relative "../test_helper"
require "tmpdir"
require "fileutils"

class TapeResolverTest < AceDemoTestCase
  def setup
    super
    @tmp = Dir.mktmpdir("ace_demo_resolver")
    @gem_root = File.join(@tmp, "gem")
    @home = File.join(@tmp, "home")
    @cwd = File.join(@tmp, "cwd")

    FileUtils.mkdir_p(File.join(@gem_root, ".ace-defaults", "demo", "tapes"))
    FileUtils.mkdir_p(File.join(@home, ".ace", "demo", "tapes"))
    FileUtils.mkdir_p(File.join(@cwd, ".ace", "demo", "tapes"))

    @resolver = Ace::Demo::Molecules::TapeResolver.new(
      gem_root: @gem_root,
      home_dir: @home,
      cwd: @cwd
    )
  end

  def teardown
    FileUtils.rm_rf(@tmp)
    super
  end

  def test_resolves_direct_path_first
    tape = File.join(@cwd, "direct.tape")
    File.write(tape, "output /tmp/direct.gif\n")

    assert_equal tape, @resolver.resolve("direct.tape")
  end

  def test_resolves_from_cascade
    default_tape = File.join(@gem_root, ".ace-defaults", "demo", "tapes", "hello.tape")
    home_tape = File.join(@home, ".ace", "demo", "tapes", "hello.tape")
    project_tape = File.join(@cwd, ".ace", "demo", "tapes", "hello.tape")

    File.write(default_tape, "output /tmp/default.gif\n")
    File.write(home_tape, "output /tmp/home.gif\n")
    File.write(project_tape, "output /tmp/project.gif\n")

    assert_equal project_tape, @resolver.resolve("hello")
  end

  def test_does_not_resolve_directory_as_tape
    dir_path = File.join(@cwd, "hello")
    FileUtils.mkdir_p(dir_path)

    default_tape = File.join(@gem_root, ".ace-defaults", "demo", "tapes", "hello.tape")
    File.write(default_tape, "output /tmp/hello.gif\n")

    assert_equal default_tape, @resolver.resolve("hello")
  end

  def test_raises_with_searched_paths
    error = assert_raises(Ace::Demo::TapeNotFoundError) do
      @resolver.resolve("missing")
    end

    assert_includes error.message, "Tape not found: missing"
    assert_includes error.message, "Searched:"
  end
end

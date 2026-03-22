# frozen_string_literal: true

require_relative "../test_helper"
require "tmpdir"
require "fileutils"

class TapeScannerTest < AceDemoTestCase
  def setup
    super
    @tmp = Dir.mktmpdir("ace_demo_scanner")
    @gem_root = File.join(@tmp, "gem")
    @home = File.join(@tmp, "home")
    @cwd = File.join(@tmp, "cwd")

    FileUtils.mkdir_p(File.join(@gem_root, ".ace-defaults", "demo", "tapes"))
    FileUtils.mkdir_p(File.join(@home, ".ace", "demo", "tapes"))
    FileUtils.mkdir_p(File.join(@cwd, ".ace", "demo", "tapes"))

    @scanner = Ace::Demo::Molecules::TapeScanner.new(
      gem_root: @gem_root,
      home_dir: @home,
      cwd: @cwd
    )
  end

  def teardown
    FileUtils.rm_rf(@tmp)
    super
  end

  def test_lists_tapes_with_override_precedence
    write_tape(File.join(@gem_root, ".ace-defaults", "demo", "tapes", "hello.tape"), "Default hello")
    write_tape(File.join(@home, ".ace", "demo", "tapes", "hello.tape"), "Home hello")
    write_tape(File.join(@cwd, ".ace", "demo", "tapes", "hello.tape"), "Project hello")
    write_tape(File.join(@home, ".ace", "demo", "tapes", "beta.tape"), "Home beta")

    list = @scanner.list

    assert_equal %w[beta hello], list.map { |item| item[:name] }
    hello = list.find { |item| item[:name] == "hello" }
    assert_equal "Project hello", hello[:description]
    assert_equal ".ace/demo/tapes/", hello[:source]
  end

  def test_find_by_name
    write_tape(File.join(@gem_root, ".ace-defaults", "demo", "tapes", "hello.tape"), "Default hello")

    result = @scanner.find("hello")

    assert_equal "hello", result[:name]
    assert_equal "Default hello", result[:description]
    assert_equal ".ace-defaults/demo/tapes/hello.tape", result[:display_path]
  end

  def test_find_by_name_does_not_require_full_list_scan
    write_tape(File.join(@gem_root, ".ace-defaults", "demo", "tapes", "hello.tape"), "Default hello")

    @scanner.define_singleton_method(:list) do
      raise "list should not be called for direct lookup"
    end

    result = @scanner.find("hello")
    assert_equal "hello", result[:name]
  end

  def test_find_supports_direct_path
    path = File.join(@cwd, "custom.tape")
    write_tape(path, "Custom direct")

    result = @scanner.find("./custom.tape")

    assert_equal "custom", result[:name]
    assert_equal "custom.tape", result[:display_path]
    assert_equal "Custom direct", result[:description]
  end

  def test_find_missing_reports_available_tapes
    write_tape(File.join(@gem_root, ".ace-defaults", "demo", "tapes", "hello.tape"), "Default hello")
    write_tape(File.join(@home, ".ace", "demo", "tapes", "beta.tape"), "Home beta")

    error = assert_raises(Ace::Demo::TapeNotFoundError) { @scanner.find("missing") }

    assert_includes error.message, "Tape not found: missing"
    assert_includes error.message, "Available tapes: beta, hello"
  end

  private

  def write_tape(path, description)
    File.write(path, <<~TAPE)
      # Description: #{description}
      # Tags: example

      Output .ace-local/demo/out.gif
    TAPE
  end
end

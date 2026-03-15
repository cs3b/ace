# frozen_string_literal: true

require_relative "../test_helper"
require "ace/support/cli"
require "tmpdir"
require "fileutils"

class CreateTest < AceDemoTestCase
  def setup
    super
    @tmp = Dir.mktmpdir("ace_demo_create_cmd")
    @orig_dir = Dir.pwd
    Dir.chdir(@tmp)
  end

  def teardown
    Dir.chdir(@orig_dir)
    FileUtils.rm_rf(@tmp)
    super
  end

  def invoke(args)
    stdout, stderr = capture_io do
      begin
        @result = Ace::Support::Cli::Runner.new(Ace::Demo::CLI).call(args: args)
      rescue SystemExit => e
        @result = e.status
      rescue Ace::Core::CLI::Error => e
        $stderr.puts e.message
        @result = e.exit_code
      end
    end

    { stdout: stdout, stderr: stderr, result: @result }
  end

  def test_creates_tape_from_args
    result = invoke(["create", "my-demo", "--", "echo hello"])

    assert_includes result[:stdout], "Created:"
    assert_includes result[:stdout], "my-demo.tape"

    tape_path = File.join(@tmp, ".ace", "demo", "tapes", "my-demo.tape")
    assert File.exist?(tape_path)

    content = File.read(tape_path)
    assert_includes content, 'Type "echo hello"'
  end

  def test_creates_tape_with_multiple_commands
    result = invoke(["create", "multi", "--", "git status", "make deploy"])

    tape_path = File.join(@tmp, ".ace", "demo", "tapes", "multi.tape")
    content = File.read(tape_path)
    assert_includes content, 'Type "git status"'
    assert_includes content, 'Type "make deploy"'
    assert_includes result[:stdout], "Created:"
  end

  def test_creates_tape_with_options
    result = invoke(["create", "opts", "--desc", "My demo", "--tags", "ci,test", "--", "echo hi"])

    tape_path = File.join(@tmp, ".ace", "demo", "tapes", "opts.tape")
    content = File.read(tape_path)
    assert_includes content, "# Description: My demo"
    assert_includes content, "# Tags: ci,test"
    assert_includes result[:stdout], "Created:"
  end

  def test_dry_run_prints_content_without_writing
    result = invoke(["create", "preview", "--dry-run", "--", "echo hello"])

    assert_includes result[:stdout], 'Type "echo hello"'
    assert_includes result[:stdout], "Output"

    tape_path = File.join(@tmp, ".ace", "demo", "tapes", "preview.tape")
    refute File.exist?(tape_path)
  end

  def test_error_when_no_commands
    result = invoke(["create", "empty"])

    assert_equal 1, result[:result]
    assert_includes result[:stderr], "No commands provided"
  end

  def test_error_on_existing_tape
    invoke(["create", "exists", "--", "echo first"])
    result = invoke(["create", "exists", "--", "echo second"])

    assert_equal 1, result[:result]
    assert_includes result[:stderr], "Tape already exists"
  end

  def test_force_overwrites_existing
    invoke(["create", "exists", "--", "echo first"])
    result = invoke(["create", "exists", "--force", "--", "echo second"])

    assert_includes result[:stdout], "Created:"
    tape_path = File.join(@tmp, ".ace", "demo", "tapes", "exists.tape")
    content = File.read(tape_path)
    assert_includes content, 'Type "echo second"'
  end

  def test_reads_from_stdin
    reader, writer = IO.pipe
    writer.puts "git status"
    writer.puts "make deploy"
    writer.close

    original_stdin = $stdin
    $stdin = reader

    result = invoke(["create", "stdin-demo"])

    $stdin = original_stdin
    reader.close

    assert_includes result[:stdout], "Created:"
    tape_path = File.join(@tmp, ".ace", "demo", "tapes", "stdin-demo.tape")
    content = File.read(tape_path)
    assert_includes content, 'Type "git status"'
    assert_includes content, 'Type "make deploy"'
  end

  def test_help_lists_create_command
    result = invoke(["--help"])
    output = result[:stdout] + result[:stderr]

    assert_includes output, "create"
  end
end

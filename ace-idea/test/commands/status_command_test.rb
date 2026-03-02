# frozen_string_literal: true

require "test_helper"
require "ace/idea/cli"
require "stringio"

class IdeaStatusCommandTest < AceIdeaTestCase
  # ---------------------------------------------------------------------------
  # Helpers
  # ---------------------------------------------------------------------------

  def run_cli(args)
    old_stdout = $stdout
    old_stderr = $stderr
    $stdout = StringIO.new
    $stderr = StringIO.new

    exit_code = 0

    begin
      Ace::Idea::IdeaCLI.start(args)
    rescue Ace::Core::CLI::Error => e
      $stderr.puts e.message
      exit_code = e.exit_code
    rescue SystemExit => e
      exit_code = e.status
    end

    { stdout: $stdout.string, stderr: $stderr.string, exit_code: exit_code }
  ensure
    $stdout = old_stdout
    $stderr = old_stderr
  end

  def with_cli_root(root_dir)
    original_new = Ace::Idea::Organisms::IdeaManager.method(:new)
    Ace::Idea::Organisms::IdeaManager.define_singleton_method(:new) do |**_opts|
      original_new.call(root_dir: root_dir)
    end
    yield
  ensure
    Ace::Idea::Organisms::IdeaManager.singleton_class.remove_method(:new)
  end

  # ---------------------------------------------------------------------------
  # Tests
  # ---------------------------------------------------------------------------

  def test_status_shows_up_next_section
    with_ideas_dir do |root|
      create_idea_fixture(root, id: "aaa111", slug: "first-idea", status: "pending")
      create_idea_fixture(root, id: "bbb222", slug: "second-idea", status: "pending")
      with_cli_root(root) do
        result = run_cli(["status"])
        assert_equal 0, result[:exit_code], result[:stderr]
        assert_match(/Up Next:/, result[:stdout])
        assert_match(/First idea/, result[:stdout])
        assert_match(/Second idea/, result[:stdout])
      end
    end
  end

  def test_status_shows_stats_line
    with_ideas_dir do |root|
      create_idea_fixture(root, id: "aaa111", slug: "pending-idea", status: "pending")
      create_idea_fixture(root, id: "bbb222", slug: "done-idea", status: "done")
      with_cli_root(root) do
        result = run_cli(["status"])
        assert_equal 0, result[:exit_code], result[:stderr]
        assert_match(/Ideas:.*total/, result[:stdout])
      end
    end
  end

  def test_status_shows_recently_done_section
    with_ideas_dir do |root|
      create_idea_fixture(root, id: "aaa111", slug: "completed-idea", status: "done")
      with_cli_root(root) do
        result = run_cli(["status"])
        assert_equal 0, result[:exit_code], result[:stderr]
        assert_match(/Recently Done:/, result[:stdout])
        assert_match(/Completed idea/, result[:stdout])
        assert_match(/\((?:just now|\d+\w+ ago)\)/, result[:stdout])
      end
    end
  end

  def test_status_up_next_excludes_special_folder_ideas
    with_ideas_dir do |root|
      create_idea_fixture(root, id: "aaa111", slug: "root-idea", status: "pending")
      create_idea_fixture(root, id: "bbb222", slug: "maybe-idea", status: "pending", special_folder: "_maybe")
      with_cli_root(root) do
        result = run_cli(["status"])
        assert_equal 0, result[:exit_code], result[:stderr]
        up_next_section = result[:stdout].split("Ideas:").first
        assert_match(/Root idea/, up_next_section)
        refute_match(/Maybe idea/, up_next_section)
      end
    end
  end

  def test_status_up_next_limit_from_cli_option
    with_ideas_dir do |root|
      create_idea_fixture(root, id: "aaa111", slug: "idea-one", status: "pending")
      create_idea_fixture(root, id: "bbb222", slug: "idea-two", status: "pending")
      create_idea_fixture(root, id: "ccc333", slug: "idea-three", status: "pending")
      with_cli_root(root) do
        result = run_cli(["status", "--up-next-limit", "1"])
        assert_equal 0, result[:exit_code], result[:stderr]
        up_next_section = result[:stdout].split("Ideas:").first
        assert_match(/Idea one/, up_next_section)
        refute_match(/Idea three/, up_next_section)
      end
    end
  end

  def test_status_recently_done_limit_from_cli_option
    with_ideas_dir do |root|
      3.times do |i|
        create_idea_fixture(root, id: "aa#{i}11#{i}", slug: "done-idea-#{i}", status: "done")
      end
      with_cli_root(root) do
        result = run_cli(["status", "--recently-done-limit", "1"])
        assert_equal 0, result[:exit_code], result[:stderr]
        done_section = result[:stdout].split("Recently Done:").last
        done_lines = done_section.lines.select { |l| l.include?("Done idea") }
        assert_equal 1, done_lines.length
      end
    end
  end

  def test_status_empty_shows_none_messages
    with_ideas_dir do |root|
      with_cli_root(root) do
        result = run_cli(["status"])
        assert_equal 0, result[:exit_code], result[:stderr]
        assert_match(/Up Next:/, result[:stdout])
        assert_match(/\(none\)/, result[:stdout])
        assert_match(/Recently Done:/, result[:stdout])
      end
    end
  end

  def test_status_recently_done_includes_archive_ideas
    with_ideas_dir do |root|
      create_idea_fixture(root, id: "aaa111", slug: "root-done", status: "done")
      create_idea_fixture(root, id: "bbb222", slug: "archived-done", status: "done", special_folder: "_archive")
      with_cli_root(root) do
        result = run_cli(["status"])
        assert_equal 0, result[:exit_code], result[:stderr]
        done_section = result[:stdout].split("Recently Done:").last
        assert_match(/Root done/, done_section)
        assert_match(/Archived done/, done_section)
      end
    end
  end
end

# frozen_string_literal: true

$LOAD_PATH.unshift File.expand_path("../lib", __dir__)

# Add parent directories for local ace dependencies during development
$LOAD_PATH.unshift File.expand_path("../../ace-support-core/lib", __dir__)
$LOAD_PATH.unshift File.expand_path("../../ace-context/lib", __dir__)
$LOAD_PATH.unshift File.expand_path("../../ace-llm/lib", __dir__)
$LOAD_PATH.unshift File.expand_path("../../ace-nav/lib", __dir__)
$LOAD_PATH.unshift File.expand_path("../../ace-git/lib", __dir__)
$LOAD_PATH.unshift File.expand_path("../../ace-git-diff/lib", __dir__)

require "ace/prompt"
require "minitest/autorun"
require "fileutils"
require "tmpdir"
require "ostruct"

class Ace::Prompt::TestCase < Minitest::Test
  def setup
    @original_dir = Dir.pwd
    @test_dir = Dir.mktmpdir
    Dir.chdir(@test_dir)
  end

  def teardown
    Dir.chdir(@original_dir)
    FileUtils.rm_rf(@test_dir) if @test_dir && File.exist?(@test_dir)
  end

  def create_prompt_file(content, path: ".cache/ace-prompt/prompts/the-prompt.md")
    FileUtils.mkdir_p(File.dirname(path))
    File.write(path, content)
    path
  end

  def create_archive_dir(base_path: ".cache/ace-prompt/prompts")
    archive_path = File.join(base_path, "archive")
    FileUtils.mkdir_p(archive_path)
    archive_path
  end
end

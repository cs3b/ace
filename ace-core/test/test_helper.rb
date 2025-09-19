# frozen_string_literal: true

$LOAD_PATH.unshift File.expand_path("../lib", __dir__)
require "ace/core"

require "minitest/autorun"
require "minitest/reporters"
require "tempfile"
require "tmpdir"
require "fileutils"

# Use spec reporter for better output
Minitest::Reporters.use! Minitest::Reporters::SpecReporter.new

# Base test case class with common utilities
class AceTestCase < Minitest::Test
  def fixture_path(path)
    File.expand_path("fixtures/#{path}", __dir__)
  end
end

# Test helper methods
module TestHelper
  def with_temp_dir
    Dir.mktmpdir do |dir|
      original_pwd = Dir.pwd
      Dir.chdir(dir)
      yield dir
    ensure
      Dir.chdir(original_pwd)
    end
  end

  def with_temp_file(content = "")
    Tempfile.create do |file|
      file.write(content)
      file.flush
      yield file.path
    end
  end

  def create_config_file(path, content)
    FileUtils.mkdir_p(File.dirname(path))
    File.write(path, content)
  end
end

# Include helper methods in both base classes
Minitest::Test.include TestHelper
AceTestCase.include TestHelper

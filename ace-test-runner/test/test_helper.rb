# frozen_string_literal: true

require "ace/test_runner"
require "ace/test_support"  # Load shared test helpers and fixtures
require "ace/support/fs"
require "minitest/autorun"

# Try to use spec reporter for better output if available
begin
  require "minitest/reporters"
  Minitest::Reporters.use! Minitest::Reporters::SpecReporter.new
rescue LoadError
  # Fall back to default reporter
end

# Test helpers
module TestHelper
  def fixture_path(name)
    File.join(__dir__, "fixtures", name)
  end

  def create_temp_test_file(content = nil)
    require "tempfile"
    file = Tempfile.new(["test_", "_test.rb"])

    content ||= <<~RUBY
      require "minitest/autorun"

      class ExampleTest < Minitest::Test
        def test_passing
          assert true
        end
      end
    RUBY

    file.write(content)
    file.close
    file.path
  end

  def with_temp_dir
    require "tmpdir"
    Dir.mktmpdir do |dir|
      Dir.chdir(dir) do
        yield dir
      end
    end
  end

  # Find the mono-repo root directory.
  # Delegates to the shared ProjectRootFinder to avoid reimplementing root detection logic.
  # @return [String] Absolute path to mono-repo root
  def find_mono_repo_root
    Ace::Support::Fs::Molecules::ProjectRootFinder.find
  end
end

class Minitest::Test
  include TestHelper
end

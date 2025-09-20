# frozen_string_literal: true

$LOAD_PATH.unshift File.expand_path("../lib", __dir__)
require "ace/test_runner"
require "minitest/autorun"
require "minitest/reporters"

# Use spec reporter for better output
Minitest::Reporters.use! Minitest::Reporters::SpecReporter.new

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
end

class Minitest::Test
  include TestHelper
end
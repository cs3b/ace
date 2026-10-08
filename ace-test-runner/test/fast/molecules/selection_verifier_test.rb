# frozen_string_literal: true
require_relative "../../test_helper"
require "ace/test_runner/molecules/selection_resolver"
require "ace/test_runner/molecules/selection_verifier"
require "tmpdir"
require "open3"
require "rbconfig"

class ExactSelectionVerifierTest < Minitest::Test
  def test_in_process_execution_runs_only_exact_identity
    Dir.mktmpdir("selected-run") do |directory|
      file = File.join(directory, "selected.rb")
      File.write(file, <<~SOURCE)
        require "minitest/autorun"
        class SelectedRunFixture < Minitest::Test
          def test_one; assert true; end
          def test_one_more; flunk "must not execute"; end
        end
      SOURCE
      runner_path = File.expand_path("../../../lib/ace/test_runner/molecules/in_process_runner", __dir__)
      script = <<~RUBY
        require #{runner_path.inspect}
        runner = Ace::TestRunner::Molecules::InProcessRunner.new(launch_env: ENV.to_h)
        result = runner.execute_tests([#{"#{file}:3".inspect}])
        STDOUT.write(result[:stdout])
        STDERR.write(result[:stderr])
        STDOUT.flush
        STDERR.flush
        exit!(result[:success] ? 0 : 1)
      RUBY
      output, error, status = Open3.capture3(RbConfig.ruby, "-e", script)
      assert status.success?, "#{output}\n#{error}"
      assert_match(/1 (?:tests|runs), 1 assertions/, output)
    end
  end

  def test_subprocess_preflight_refuses_before_loading_any_selected_file
    require "ace/test_runner/atoms/command_builder"
    Dir.mktmpdir("selection-refusal") do |directory|
      file = File.join(directory, "selected.rb")
      marker = File.join(directory, "loaded")
      File.write(file, "File.write(#{marker.inspect}, 'loaded')\nclass Selected; def test_one; end; end\n")
      builder = Ace::TestRunner::Atoms::CommandBuilder.new(bundler: false)
      error_class = Ace::TestRunner::Atoms::LineNumberResolver::SelectionError
      assert_raises(error_class) { builder.build_test_command(["#{file}:2", "#{file}:1"]) }
      assert_raises(error_class) { builder.build_test_command([file, "#{file}:2"]) }
      assert_raises(error_class) { builder.build_test_command(["#{file}:0"]) }
      refute File.exist?(marker)
    end
  end

  def test_subprocess_refuses_source_change_after_plan_creation
    require "ace/test_runner/atoms/command_builder"
    Dir.mktmpdir("selection-drift") do |directory|
      file = File.join(directory, "selected.rb")
      marker = File.join(directory, "loaded")
      File.write(file, "class Selected; def test_one; end; end\n")
      builder = Ace::TestRunner::Atoms::CommandBuilder.new(ruby_command: RbConfig.ruby, bundler: false)
      command = builder.build_test_command(["#{file}:1"])
      File.write(file, "File.write(#{marker.inspect}, 'loaded')\n")
      _output, error, status = Open3.capture3(*command)
      refute status.success?
      assert_includes error, "Selected test source changed"
      refute File.exist?(marker)
    end
  end

  def test_subprocess_refuses_method_excluded_by_runnable_methods
    require "ace/test_runner/atoms/command_builder"
    Dir.mktmpdir("selection-hidden") do |directory|
      file = File.join(directory, "selected.rb")
      marker = File.join(directory, "executed")
      File.write(file, <<~SOURCE)
        require "minitest/autorun"
        class HiddenSelectedFixture < Minitest::Test
          def self.runnable_methods; []; end
          def test_one; File.write(#{marker.inspect}, "executed"); end
        end
      SOURCE
      builder = Ace::TestRunner::Atoms::CommandBuilder.new(ruby_command: RbConfig.ruby, bundler: false)
      command = builder.build_test_command(["#{file}:4"])
      _output, error, status = Open3.capture3(*command)
      refute status.success?
      assert_includes error, "does not match loaded runnable"
      refute File.exist?(marker)
    end
  end

  def test_per_file_execution_deduplicates_selected_identity
    require "ace/test_runner/atoms/command_builder"
    require "ace/test_runner/molecules/test_executor"
    Dir.mktmpdir("selection-per-file") do |directory|
      file = File.join(directory, "selected.rb")
      marker = File.join(directory, "executed")
      File.write(file, <<~SOURCE)
        require "minitest/autorun"
        class PerFileSelectedFixture < Minitest::Test
          def test_one; File.open(#{marker.inspect}, "a") { |io| io.puts("one") }; assert true; end
          def test_one_more; flunk "not selected"; end
        end
      SOURCE
      builder = Ace::TestRunner::Atoms::CommandBuilder.new(ruby_command: RbConfig.ruby, bundler: false)
      executor = Ace::TestRunner::Molecules::TestExecutor.new(command_builder: builder, launch_env: ENV.to_h)
      result = executor.execute_with_progress(["#{file}:3", "#{file}:3"], per_file: true)
      assert result[:success], result.inspect
      assert_equal ["one"], File.readlines(marker, chomp: true)
    end
  end

  def test_loaded_identity_source_and_anchored_filter
    Dir.mktmpdir("selection-verification") do |directory|
      file = File.join(directory, "selected.rb")
      File.write(file, "class SelectedIdentityFixture < Minitest::Test; def test_one; end; end\n")
      plan = Ace::TestRunner::Molecules::SelectionResolver.resolve(["#{file}:1"])
      load file
      verifier = Ace::TestRunner::Molecules::SelectionVerifier
      pattern = Regexp.new(verifier.verify_loaded!(plan, runnables: [SelectedIdentityFixture]))
      assert_match pattern, "SelectedIdentityFixture#test_one"
      refute_match pattern, "SelectedIdentityFixture#test_one_more"
      refute_match pattern, "Other#test_one"
      assert_raises(Ace::TestRunner::Atoms::LineNumberResolver::SelectionError) do
        verifier.verify_loaded!(plan, runnables: [])
      end
      File.write(file, "# changed\n")
      assert_raises(Ace::TestRunner::Atoms::LineNumberResolver::SelectionError) { verifier.verify_sources!(plan) }
    ensure
      if Object.const_defined?(:SelectedIdentityFixture)
        Minitest::Runnable.runnables.delete(SelectedIdentityFixture)
        Object.send(:remove_const, :SelectedIdentityFixture)
      end
    end
  end
end

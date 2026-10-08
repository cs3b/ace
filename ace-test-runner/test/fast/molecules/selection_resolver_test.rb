# frozen_string_literal: true
require_relative "../../test_helper"
require "ace/test_runner/molecules/selection_resolver"
require "ace/test_runner/molecules/cli_argument_parser"
require "tmpdir"

class ExactSelectionResolverTest < Minitest::Test
  Resolver = Ace::TestRunner::Molecules::SelectionResolver
  SelectionError = Ace::TestRunner::Atoms::LineNumberResolver::SelectionError

  def with_fixture
    Dir.mktmpdir("selection-plan") do |directory|
      file = File.join(directory, "example_test.rb")
      File.write(file, "raise 'must not load during selection'\nclass Example; def test_one; end; end\n")
      yield file
    end
  end

  def test_preflight_resolves_without_loading_and_deduplicates_identity
    with_fixture do |file|
      plan = Resolver.resolve(["#{file}:2", "#{file}:2"])
      assert plan.qualified?
      assert_equal [file], plan.files
      assert_equal 1, plan.identities.size
      assert_equal "Example", plan.identities.first.fetch(:class_name)
      assert_equal Digest::SHA256.file(file).hexdigest, plan.source_digests.fetch(file)
      assert_raises(FrozenError) { plan.files.first.replace("other") }
      assert_raises(FrozenError) { plan.identities.first[:name].replace("other") }
      assert_raises(FrozenError) { plan.source_digests.clear }
    end
  end

  def test_same_runtime_identity_in_distinct_files_refuses_before_loading
    with_fixture do |file|
      other = File.join(File.dirname(file), "other_test.rb")
      File.write(other, File.read(file))
      error = assert_raises(SelectionError) { Resolver.resolve(["#{file}:2", "#{other}:2"]) }
      assert_includes error.message, "Ambiguous test identity across files"
    end
  end

  def test_one_invalid_selector_refuses_entire_plan_without_loading
    with_fixture do |file|
      assert_raises(SelectionError) { Resolver.resolve(["#{file}:2", "#{file}:1"]) }
      assert_raises(SelectionError) { Resolver.resolve(["#{file}:2", "#{file}.missing.rb:2"]) }
    end
  end

  def test_mixed_whole_file_and_line_selection_explicitly_refuses
    with_fixture do |file|
      error = assert_raises(SelectionError) { Resolver.resolve([file, "#{file}:2"]) }
      assert_includes error.message, "Mixed whole-file"
    end
  end

  def test_whole_file_selection_preserves_input_without_freezing_caller
    files = [+"example.rb"]
    plan = Resolver.resolve(files)
    refute plan.qualified?
    assert_equal files, plan.files
    files.first.replace("changed.rb")
    assert_equal ["example.rb"], plan.files
  end

  def test_cli_rejects_malformed_line_suffix_before_package_resolution
    %w[example.rb:0 example.rb:-1 example.rb:abc].each do |selector|
      parser = Ace::TestRunner::Molecules::CliArgumentParser.new([selector], package_resolver: Object.new)
      assert_raises(SelectionError) { parser.parse }
    end
  end
end

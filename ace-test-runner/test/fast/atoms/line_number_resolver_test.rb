# frozen_string_literal: true
require_relative "../../test_helper"
require "ace/test_runner/atoms/line_number_resolver"
require "tmpdir"

class ExactLineNumberResolverTest < Minitest::Test
  Resolver = Ace::TestRunner::Atoms::LineNumberResolver

  def with_source(source)
    Dir.mktmpdir("selection") do |directory|
      file = File.join(directory, "example_test.rb")
      File.write(file, source)
      yield file
    end
  end

  def test_nested_syntax_and_closing_delimiter_are_exact
    source = <<~'SOURCE'
      module Outer
        class Example < Minitest::Test
          def test_one
            2.times do
              text = "def test_other; end"
            end
          end

          def helper
          end
          def test_one_more
          end
        end
      end
    SOURCE
    with_source(source) do |file|
      (3..7).each do |line|
        identity = Resolver.resolve_identity(file, line)
        assert_equal ["Outer::Example", "test_one", 3, 7], identity.values_at(:class_name, :name, :start_line, :end_line)
      end
      [1, 2, 8, 9, 10, 13, 14, 0, -1, 99].each do |line|
        assert_raises(Resolver::SelectionError) { Resolver.resolve_identity(file, line) }
      end
      assert_equal "test_one_more", Resolver.resolve_test_at_line(file, 11)
    end
  end

  def test_literal_multiline_dsl_and_heredoc_ignore_fake_syntax
    source = <<~'SOURCE'
      class Example
        test(
          "two words"
        ) do
          text = <<~TEXT
            def test_fake
            end
          TEXT
        end
      end
    SOURCE
    with_source(source) do |file|
      (2..9).each do |line|
        identity = Resolver.resolve_identity(file, line)
        assert_equal ["Example", "test_two_words", 4], identity.values_at(:class_name, :name, :method_line)
      end
    end
  end

  def test_dynamic_conditional_singleton_duplicate_and_reopened_identities_refuse
    sources = [
      "class Example; if true; def test_one; end; end; end",
      'class Example; test "#{name}" do; end; end',
      "class Example; def self.test_one; end; end",
      "class Example; def test_one; end; def test_one; end; end",
      "class Example; def test_one; end; end\nclass Example; def helper; end; end",
      "Object.new.instance_eval { def test_one; end }",
      "class Example; def test_one"
    ]
    sources.each do |source|
      with_source(source) { |file| assert_raises(Resolver::SelectionError) { Resolver.resolve_identity(file, 1) } }
    end
  end

  def test_same_name_in_different_classes_has_distinct_identity
    with_source("class First; def test_same; end; end\nclass Second; def test_same; end; end\n") do |file|
      assert_equal "First", Resolver.resolve_identity(file, 1).fetch(:class_name)
      assert_equal "Second", Resolver.resolve_identity(file, 2).fetch(:class_name)
    end
  end

  def test_invalid_suffix_and_missing_file_refuse
    %w[foo.rb:0 foo.rb:-1 foo.rb:abc foo.rb:1:2].each do |selector|
      assert_raises(Resolver::SelectionError) { Resolver.parse_file_with_line(selector) }
    end
    assert_equal({file: "foo.rb", line: 2}, Resolver.parse_file_with_line("foo.rb:2"))
    assert_equal({file: "foo.rb", line: nil}, Resolver.parse_file_with_line("foo.rb"))
    assert_raises(Resolver::SelectionError) { Resolver.resolve_identity("/missing/test.rb", 1) }
  end
end

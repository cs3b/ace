# frozen_string_literal: true

require_relative "../test_helper"
require "tmpdir"

class SourceResolverTest < AceSimTestCase
  def setup
    super
    @resolver = Ace::Sim::Molecules::SourceResolver.new
  end

  def test_resolves_existing_file_path
    Dir.mktmpdir do |dir|
      file = File.join(dir, "source.md")
      File.write(file, "hello")

      result = @resolver.resolve(file)

      assert_equal File.expand_path(file), result["path"]
      assert_equal ["path"], result.keys
    end
  end

  def test_rejects_empty_source
    assert_raises(Ace::Sim::ValidationError) { @resolver.resolve("  ") }
  end

  def test_rejects_missing_source_file
    err = assert_raises(Ace::Sim::ValidationError) { @resolver.resolve("missing-source.md") }
    assert_match(/source file not found/, err.message)
  end
end

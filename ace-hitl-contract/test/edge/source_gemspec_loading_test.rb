# frozen_string_literal: true

require_relative "../test_helper"
require "rubygems/package"

class SourceGemspecLoadingTest < AceHitlContractTestCase
  def test_build_manifest_is_independent_of_wrong_cwd_cached_load_order
    Dir.mktmpdir("ace-spec-order", "/tmp") do |scratch|
      package = File.join(scratch, "package")
      other = File.join(scratch, "other")
      [package, other].each { |dir| FileUtils.mkdir_p(File.join(dir, "lib")) }
      File.write(File.join(package, "lib/correct.rb"), "# correct package\n")
      File.write(File.join(other, "lib/wrong.rb"), "# another cwd\n")
      path = File.join(package, "order-proof.gemspec")
      File.write(path, <<~RUBY)
        Gem::Specification.new do |s|
          s.name = "order-proof"
          s.version = "0.1.0"
          s.authors = ["ACE tests"]
          s.summary = "Source spec order fixture"
          s.files = Dir.glob("lib/**/*.rb")
        end
      RUBY
      cached = Dir.chdir(other) { Gem::Specification.load(path) }
      assert_equal ["lib/wrong.rb"], cached.files
      # Both loader orderings must be fresh and package-relative even when
      # the global cache still contains the earlier wrong-cwd evaluation.
      2.times do
        spec = Dir.chdir(other) { load_source_gemspec(path) }
        refute_same cached, spec
        assert_equal ["lib/correct.rb"], spec.files
        assert_equal path, spec.loaded_from
        archive = File.join(scratch, "order-proof.gem")
        Dir.chdir(package) { Gem::Package.build(spec, false, false, archive) }
        assert_equal ["lib/correct.rb"], Gem::Package.new(archive).contents
      end
      assert_same cached, Gem::Specification.load(path), "loader changed the global cache"
    end
  end
end

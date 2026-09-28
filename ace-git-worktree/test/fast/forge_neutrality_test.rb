# frozen_string_literal: true

require "test_helper"

# Coupling audit: the worktree package must stay forge-neutral. Provider
# execution lives exclusively in ace-git-github/ace-git-forgejo behind the
# ace-git provider contract; no GitHub-only fetcher, dependency, or raw
# provider-CLI parsing may return to worktree correctness paths.
class ForgeNeutralityTest < Minitest::Test
  LIB_DIR = File.expand_path("../../lib", __dir__)
  GEMSPEC = File.expand_path("../../ace-git-worktree.gemspec", __dir__)

  FORBIDDEN_PATTERNS = [
    [/require\s+["']ace\/git\/github["']/, "direct ace/git/github require"],
    [/require\s+["']ace\/git\/forgejo["']/, "direct ace/git/forgejo require"],
    [/Github::PrFetcher/, "GitHub PrFetcher coupling"],
    [/Github::IssueSync/, "GitHub issue sync coupling"],
    [/\bPrCreator\b/, "removed gh-based PrCreator"],
    [/Open3\.capture3\(\s*(?:env,\s*)?["']gh["']/, "raw gh invocation"],
    [/Open3\.capture3\(\s*(?:env,\s*)?["']fj["']/, "raw fj invocation"]
  ].freeze

  def test_worktree_library_has_no_direct_provider_coupling
    each_lib_ruby_file do |path, source|
      FORBIDDEN_PATTERNS.each do |pattern, label|
        refute pattern.match?(source), "#{path} contains #{label}"
      end
    end
  end

  def test_gemspec_declares_only_the_neutral_core_dependency
    source = File.read(GEMSPEC)
    refute source.match?(/ace-git-github/), "gemspec must not depend on ace-git-github"
    refute source.match?(/ace-git-forgejo/), "gemspec must not depend on ace-git-forgejo"
    assert source.match?(/add_dependency\s+["']ace-git["']/), "gemspec must depend on the neutral ace-git core"
  end

  private

  def each_lib_ruby_file
    Dir.glob(File.join(LIB_DIR, "**/*.rb")).sort.each do |path|
      yield path, File.read(path)
    end
  end
end

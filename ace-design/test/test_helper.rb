# frozen_string_literal: true
$LOAD_PATH.unshift File.expand_path("../lib", __dir__)
require "ace/design"
require "minitest/autorun"
require "tmpdir"
require "fileutils"
require "stringio"
class DesignTest < Minitest::Test
  def with_session
    Dir.mktmpdir("ace-design-test-") do |root|
      File.write(File.join(root, "session.json"), JSON.generate({surface: "site", title: "Mock & <test>", language: "en", variants: %w[a b c]}))
      File.write(File.join(root, "fixtures.json"), JSON.generate({title: "Shared title", rows: [1, 2, 3]}))
      File.write(File.join(root, "brief.md"), "One subject, three directions")
      %w[a b c].each do |id|
        dir = File.join(root, "variants", id)
        FileUtils.mkdir_p(dir)
        File.write(File.join(dir, "index.html"), "<h1>#{id}</h1>")
        File.write(File.join(dir, "direction.md"), "Direction #{id}")
      end
      yield root
    end
  end
  def choose(root, variant: "a", hash: nil)
    data = {surface: "site", variant: variant,
      fixtures_sha256: hash || Digest::SHA256.file(File.join(root, "fixtures.json")).hexdigest,
      variant_sha256: File.directory?(File.join(root, "variants", variant)) ? Ace::Design::Molecules::Artifacts.digest(File.join(root, "variants", variant)) : "missing",
      decisions: ["Keep the composition"]}
    File.write(File.join(root, "selection.json"), JSON.generate(data))
  end
end

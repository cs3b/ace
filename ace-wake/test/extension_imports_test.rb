# frozen_string_literal: true

require_relative "test_helper"
require "ace/wake"

# Import hygiene for the published extension (guard restored after it was
# dropped in d8b239437): the extension loads inside the Pi SDK runtime
# with no bundled node_modules, so every shipped JavaScript file may only
# import relative modules and node builtins — a bare npm import would
# break the deployed extension at load time.
class ExtensionImportsTest < Minitest::Test
  IMPORT_PATTERN = /import\s+[^"']*["']([^"']+)["']|import\s+["']([^"']+)["']|export\s+[^"']*from\s+["']([^"']+)["']/.freeze

  def test_shipped_javascript_imports_only_relative_modules_and_node_builtins
    files = Dir.glob(File.join(Ace::Wake.extension_root, "**", "*.js")).sort
    refute_empty files, "extension sources not found under #{Ace::Wake.extension_root}"

    offenders = files.flat_map do |file|
      imports = File.read(file).scan(IMPORT_PATTERN).flatten.compact.uniq
      imports.reject { |name| name.start_with?(".", "node:") }
        .map { |name| "#{file.sub("#{Ace::Wake.extension_root}/", "")}: #{name}" }
    end

    assert_empty offenders,
      "the extension must rely only on relative modules and node builtins:\n#{offenders.join("\n")}"
  end
end

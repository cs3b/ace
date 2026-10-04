# frozen_string_literal: true

require "ace/test_support"
require "ace/hitl/contract"

class AceHitlContractTestCase < AceTestCase
  # Gem::Specification.load caches mutable objects by filename. A prior
  # load from another cwd can cache the wrong Dir.glob-based file manifest.
  # Evaluate source specs freshly without touching RubyGems activation/cache.
  def load_source_gemspec(path)
    path = File.expand_path(path)
    Dir.chdir(File.dirname(path)) do
      spec = eval(File.read(path), TOPLEVEL_BINDING, path)
      raise "invalid source gemspec: #{path}" unless spec.is_a?(Gem::Specification)
      spec.loaded_from = path
      spec
    end
  end

  def with_env(values)
    saved = values.to_h { |key, _| [key, ENV[key]] }
    values.each { |key, value| value.nil? ? ENV.delete(key) : ENV[key] = value }
    yield
  ensure
    saved.each { |key, value| value.nil? ? ENV.delete(key) : ENV[key] = value }
  end
end

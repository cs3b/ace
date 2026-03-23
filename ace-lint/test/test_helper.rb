# frozen_string_literal: true

$LOAD_PATH.unshift File.expand_path("../lib", __dir__)

# Add ace-support-core to load path first (dependency)
ace_support_core_path = File.expand_path("../../ace-support-core/lib", __dir__)
$LOAD_PATH.unshift(ace_support_core_path) if Dir.exist?(ace_support_core_path)

# Add ace-support-config to load path (depends on ace-support-core)
ace_support_config_path = File.expand_path("../../ace-support-config/lib", __dir__)
$LOAD_PATH.unshift(ace_support_config_path) if Dir.exist?(ace_support_config_path)

require "ace/lint"

require "minitest/autorun"

# Global hook to reset caches before each test
# Use before_setup to run before each test class's setup method
#
# NOTE: We intentionally do NOT reset ValidatorRegistry availability cache here.
# That cache holds subprocess availability checks which are expensive (~0.5-1s each).
# Tests that need to stub availability should reset it in their own setup.
module CacheReset
  def before_setup
    super
    Ace::Lint::Atoms::ConfigLocator.reset_cache! if defined?(Ace::Lint::Atoms::ConfigLocator)
  end
end

Minitest::Test.include(CacheReset)

# Pre-warm caches to avoid random first-test slowness.
# This forces lazy initialization to happen once at require time.
Ace::Lint.config
begin
  Ace::Lint.kramdown_config
rescue
  nil
end
begin
  Ace::Lint.ruby_config
rescue
  nil
end
begin
  Ace::Lint.markdown_config
rescue
  nil
end

# Pre-warm validator availability caches (subprocess calls).
# There are two separate caches:
# 1. ValidatorRegistry.@availability_cache - used by registry lookups
# 2. BaseRunner.@availability_cache - used by direct runner calls
# Both need to be pre-warmed to avoid random first-test slowness.
begin
  Ace::Lint::Atoms::ValidatorRegistry.available?(:standardrb)
rescue
  nil
end
begin
  Ace::Lint::Atoms::ValidatorRegistry.available?(:rubocop)
rescue
  nil
end
begin
  Ace::Lint::Atoms::StandardrbRunner.available?
rescue
  nil
end
begin
  Ace::Lint::Atoms::RuboCopRunner.available?
rescue
  nil
end

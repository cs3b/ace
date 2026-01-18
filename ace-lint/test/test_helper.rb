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
module CacheReset
  def before_setup
    super
    Ace::Lint::Atoms::ValidatorRegistry.reset_cache! if defined?(Ace::Lint::Atoms::ValidatorRegistry)
    Ace::Lint::Atoms::ConfigLocator.reset_cache! if defined?(Ace::Lint::Atoms::ConfigLocator)
  end
end

Minitest::Test.include(CacheReset)

# frozen_string_literal: true

$LOAD_PATH.unshift File.expand_path("../lib", __dir__)

# Add ace-support-core to load path if it exists
ace_support_core_path = File.expand_path("../../ace-support-core/lib", __dir__)
$LOAD_PATH.unshift(ace_support_core_path) if Dir.exist?(ace_support_core_path)

require "ace/prompt"

require "minitest/autorun"
require "fileutils"
require "tmpdir"

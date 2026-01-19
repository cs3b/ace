# frozen_string_literal: true

$LOAD_PATH.unshift File.expand_path("../lib", __dir__)

# Add ace-support-core to load path if it exists
ace_support_core_path = File.expand_path("../../ace-support-core/lib", __dir__)
$LOAD_PATH.unshift(ace_support_core_path) if Dir.exist?(ace_support_core_path)

# Add ace-bundle to load path if it exists
ace_bundle_path = File.expand_path("../../ace-bundle/lib", __dir__)
$LOAD_PATH.unshift(ace_bundle_path) if Dir.exist?(ace_bundle_path)

# Load ace-git for stubbing Ace::Git::Molecules::BranchReader in tests
ace_git_path = File.expand_path("../../ace-git/lib", __dir__)
$LOAD_PATH.unshift(ace_git_path) if Dir.exist?(ace_git_path)

require "ace/prompt_prep"

require "minitest/autorun"
require "fileutils"
require "tmpdir"

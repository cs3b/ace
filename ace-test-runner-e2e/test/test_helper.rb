# frozen_string_literal: true

# Deterministic project-root discovery: the hermetic suite strips the
# mise-injected ambient PROJECT_ROOT_PATH, and the marker-walk fallback
# stops at this package's Rakefile, hiding the repo .ace/llm config from
# the config cascade (role: resolution). Pin the workspace root so
# behavior is identical standalone and under ace-test-suite.
ENV["PROJECT_ROOT_PATH"] = File.expand_path("../..", __dir__)

$LOAD_PATH.unshift File.expand_path("../lib", __dir__)

# Add dependencies to load path for monorepo development
%w[ace-support-core ace-support-config ace-llm ace-b36ts].each do |dep|
  dep_path = File.expand_path("../../#{dep}/lib", __dir__)
  $LOAD_PATH.unshift(dep_path) if Dir.exist?(dep_path)
end

# Add provider gems that ace-llm depends on
%w[ace-llm-providers-cli].each do |dep|
  dep_path = File.expand_path("../../#{dep}/lib", __dir__)
  $LOAD_PATH.unshift(dep_path) if Dir.exist?(dep_path)
end

require "ace/test/end_to_end_runner"

require "minitest/autorun"
require "tmpdir"
require "fileutils"

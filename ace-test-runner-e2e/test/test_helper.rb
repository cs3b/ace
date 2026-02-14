# frozen_string_literal: true

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

# frozen_string_literal: true

$LOAD_PATH.unshift File.expand_path("../lib", __dir__)

# Resolve monorepo dependencies from workspace sources, not installed gems
# (the installed ace-handbook may lag the in-repo version; see ace-herdr).
%w[ace-handbook].each do |pkg|
  lib = File.expand_path("../../#{pkg}/lib", __dir__)
  $LOAD_PATH.unshift(lib) if Dir.exist?(lib)
end

require "minitest/autorun"
require "ace/handbook/integration/pi"

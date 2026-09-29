# frozen_string_literal: true

require_relative "fs/version"
require_relative "fs/errors"
require_relative "fs/atoms/path_expander"
require_relative "fs/molecules/project_root_finder"
require_relative "fs/molecules/directory_traverser"

module Ace
  module Support
    # Filesystem utilities for ace-* gems
    #
    # Provides unified path expansion, project root detection, and directory traversal
    # functionality extracted from ace-support-core and ace-config.
    #
    # Components:
    # - Atoms::PathExpander - Path expansion with protocol, env var, and relative path support
    # - Molecules::ProjectRootFinder - Project root detection based on marker files
    # - Molecules::DirectoryTraverser - Config directory discovery in directory hierarchy
    module Fs
    end
  end
end

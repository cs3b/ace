# frozen_string_literal: true

require "fileutils"
require "ace/support/items"

module Ace
  module Support
    module Items
      module Atoms
        # Creates persistent, project-local temporary workspace directories.
        module TmpWorkspace
          module_function

          # Create a workspace directory for ephemeral work that should remain
          # discoverable for debugging.
          #
          # @param label [String] Identifying label for the workspace path
          # @param project_root [String, nil] Optional explicit project root
          # @param time [Time] Optional timestamp for deterministic pathing
          # @return [String] Absolute workspace directory path
          def create(label, project_root: nil, time: Time.now)
            raise ArgumentError, "label is required" if label.nil? || label.to_s.empty?

            root = project_root || Ace::Support::Fs::Molecules::ProjectRootFinder.find_or_current
            partition = Atoms::DatePartitionPath.compute(time)
            b36ts = ::Ace::B36ts.encode(time)

            workspace_dir = File.join(root, ".ace-local", "tmp", partition, "#{b36ts}-#{label}")
            FileUtils.mkdir_p(workspace_dir)

            workspace_dir
          end
        end
      end
    end
  end
end

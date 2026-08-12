# frozen_string_literal: true

require "open3"
require_relative "../atoms/git_command"

module Ace
  module Git
    module Worktree
      module Molecules
        # Toolchain truster molecule
        #
        # Discovers tracked mise configuration files and executes/verifies toolchain trust.
        # Fails closed on required policy when trust fails or cannot be verified.
        class ToolchainTruster
          def initialize(project_root: Dir.pwd, policy: "required")
            @project_root = project_root
            @policy = (policy.to_s.strip == "advisory") ? "advisory" : "required"
          end

          # Discover tracked mise configuration files in the project
          #
          # @return [Array<String>] List of repository-relative paths to tracked mise configs
          def discover_tracked_configs
            result = Atoms::GitCommand.execute("ls-files", timeout: 10)
            return [] unless result[:success] && result[:output]

            tracked_files = result[:output].lines.map(&:strip).reject(&:empty?)
            tracked_files.select do |file|
              basename = File.basename(file)
              basename == ".mise.toml" ||
                basename == "mise.toml" ||
                file == ".mise/config.toml" ||
                file == ".config/mise/config.toml" ||
                basename.end_with?(".mise.toml") ||
                (basename.start_with?(".mise") && basename.end_with?(".toml"))
            end.uniq
          end

          # Run toolchain trust verification for tracked configuration files
          #
          # @param target_dir [String, nil] Target directory (e.g. worktree path) to run trust in
          # @return [Hash] Phase result with :phase, :policy, :tracked_files, :status, :evidence
          def verify_and_trust(target_dir = nil)
            dir = target_dir || @project_root
            tracked = discover_tracked_configs

            if tracked.empty?
              return {
                phase: "toolchain_trust",
                policy: @policy,
                tracked_files: [],
                status: "not_applicable",
                evidence: "No tracked mise configuration files found"
              }
            end

            # Check if mise binary is available
            stdout, stderr, status = Open3.capture3("which", "mise")
            unless status.success?
              failed_status = (@policy == "required") ? "required_failed" : "advisory_failed"
              return {
                phase: "toolchain_trust",
                policy: @policy,
                tracked_files: tracked,
                status: failed_status,
                evidence: "mise CLI is not available in PATH"
              }
            end

            file_evidences = {}
            all_succeeded = true

            tracked.each do |rel_path|
              abs_path = File.expand_path(rel_path, dir)
              target_file = File.exist?(abs_path) ? abs_path : File.expand_path(rel_path, @project_root)

              unless File.exist?(target_file)
                file_evidences[rel_path] = "File missing or deleted"
                all_succeeded = false
                next
              end

              stdout_t, stderr_t, status_t = Open3.capture3("mise", "trust", target_file, chdir: dir)
              if status_t.success?
                file_evidences[rel_path] = "trusted"
              else
                all_succeeded = false
                file_evidences[rel_path] = "mise trust failed: #{stderr_t.strip.empty? ? stdout_t.strip : stderr_t.strip}"
              end
            end

            final_status = if all_succeeded
              "succeeded"
            elsif @policy == "required"
              "required_failed"
            else
              "advisory_failed"
            end

            {
              phase: "toolchain_trust",
              policy: @policy,
              tracked_files: tracked,
              status: final_status,
              evidence: file_evidences
            }
          end
        end
      end
    end
  end
end

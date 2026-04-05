# frozen_string_literal: true

require "open3"

module Ace
  module Hitl
    module Molecules
      class WorktreeScopeResolver
        VALID_SCOPES = %w[current all].freeze

        def default_scope
          main_checkout? ? "all" : "current"
        end

        def effective_scope(requested_scope)
          requested_scope || default_scope
        end

        def current_worktree_root
          @current_worktree_root ||= git_output("rev-parse", "--show-toplevel")
        end

        def worktree_roots(scope:)
          case scope
          when "current"
            [current_worktree_root].compact
          when "all"
            roots = parse_worktree_list
            roots = [current_worktree_root].compact if roots.empty?
            roots
          else
            []
          end
        end

        private

        def main_checkout?
          current = current_worktree_root
          common_root = git_common_root
          return false if current.nil? || common_root.nil?

          File.expand_path(current) == File.expand_path(common_root)
        end

        def parse_worktree_list
          output = git_output("worktree", "list", "--porcelain")
          return [] if output.nil? || output.empty?

          roots = output.lines.filter_map do |line|
            next unless line.start_with?("worktree ")

            line.sub("worktree ", "").strip
          end
          roots.uniq
        end

        def git_common_root
          common_dir = git_output("rev-parse", "--path-format=absolute", "--git-common-dir")
          return nil if common_dir.nil? || common_dir.empty?

          File.dirname(common_dir)
        end

        def git_output(*args)
          stdout, status = Open3.capture2("git", *args)
          return nil unless status.success?

          output = stdout.to_s.strip
          output.empty? ? nil : output
        rescue StandardError
          nil
        end
      end
    end
  end
end

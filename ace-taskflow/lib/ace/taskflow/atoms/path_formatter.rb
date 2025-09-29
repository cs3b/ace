# frozen_string_literal: true

module Ace
  module Taskflow
    module Atoms
      module PathFormatter
        class << self
          def format_relative_path(absolute_path, root_path = nil)
            return "" if absolute_path.nil? || absolute_path.empty?

            root = root_path || Dir.pwd

            # Remove the root path and the leading slash only
            relative = absolute_path.sub(/^#{Regexp.escape(root)}\//, "")

            # If nothing was removed, the path might already be relative
            relative == absolute_path && !absolute_path.start_with?("/") ? absolute_path : relative
          end

          def format_display_path(absolute_path, root_path = nil, max_length: 70)
            relative = format_relative_path(absolute_path, root_path)

            return relative if relative.length <= max_length

            # Smart truncation for .ace-taskflow paths
            if relative.start_with?(".ace-taskflow/")
              parts = relative.split("/")
              if parts.length >= 4
                # .ace-taskflow/release/subfolder/filename.md
                prefix = parts[0..2].join("/")  # .ace-taskflow/v.0.9.0/ideas
                filename = parts[-1]

                # Check if we can fit the important parts
                if (prefix.length + filename.length + 4) <= max_length
                  return "#{prefix}/.../#{filename}"
                end
              end
            end

            # Default truncation: keep beginning and end
            start_length = (max_length - 3) / 2
            end_length = max_length - 3 - start_length
            "#{relative[0...start_length]}...#{relative[-end_length..]}"
          end
        end
      end
    end
  end
end
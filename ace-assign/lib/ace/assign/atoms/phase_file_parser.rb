# frozen_string_literal: true

require "yaml"

module Ace
  module Assign
    module Atoms
      # Pure functions for parsing phase markdown files.
      #
      # Phase files have frontmatter + body structure:
      # ---
      # name: phase-name
      # status: pending
      # ---
      # # Instructions
      # ...
      module PhaseFileParser
        FRONTMATTER_REGEX = /\A---\s*\n(.*?)\n---\s*\n/m

        # Parse phase file content into structured data
        #
        # @param content [String] File content with frontmatter + body
        # @return [Hash] Parsed data with :frontmatter and :body keys
        def self.parse(content)
          match = content.match(FRONTMATTER_REGEX)

          if match
            frontmatter_yaml = match[1]
            body = content[match.end(0)..]

            frontmatter = YAML.safe_load(frontmatter_yaml, permitted_classes: [Time, Date]) || {}
            { frontmatter: frontmatter, body: body.strip }
          else
            { frontmatter: {}, body: content.strip }
          end
        end

        # Extract specific fields from parsed content
        #
        # @param parsed [Hash] Result from parse()
        # @return [Hash] Extracted fields
        def self.extract_fields(parsed)
          fm = parsed[:frontmatter]
          body = parsed[:body]

          context = fm["context"]
          validate_context!(context)

          {
            name: fm["name"],
            status: (fm["status"] || "pending").to_sym,
            skill: fm["skill"],
            context: context, # "fork" triggers Task tool execution
            batch_parent: parse_boolean(fm["batch_parent"]),
            parallel: parse_boolean(fm["parallel"]),
            max_parallel: parse_positive_integer(fm["max_parallel"]),
            fork_retry_limit: parse_non_negative_integer(fm["fork_retry_limit"]),
            started_at: parse_time(fm["started_at"]),
            completed_at: parse_time(fm["completed_at"]),
            fork_launch_pid: parse_integer(fm["fork_launch_pid"]),
            fork_tracked_pids: parse_integer_array(fm["fork_tracked_pids"]),
            fork_pid_updated_at: parse_time(fm["fork_pid_updated_at"]),
            fork_pid_file: fm["fork_pid_file"],
            error: fm["error"],
            stall_reason: fm["stall_reason"],
            added_by: fm["added_by"],
            parent: fm["parent"],
            instructions: body.strip,
            report: nil # Reports are loaded separately from reports/ dir
          }
        end

        # Extract instructions section from body
        # Body is now just instructions (report is in separate file)
        #
        # @param body [String] File body after frontmatter
        # @return [String] Instructions content
        def self.extract_instructions(body)
          body.strip
        end

        # Parse filename to extract number, name, and parent.
        #
        # @param filename [String] Filename like "010-init-project.ph.md" or "010-init-project.r.md"
        # @return [Hash] Extracted number, name, and parent (if nested)
        def self.parse_filename(filename)
          # Remove .ph.md or .r.md extension
          base = filename.sub(/\.(ph|r)\.md$/, "")

          # Match number pattern (with optional dot-separated parts) and name
          match = base.match(/^([\d.]+)-(.+)$/)

          if match
            number = match[1]
            name = match[2]
            parent = extract_parent_from_number(number)
            { number: number, name: name, parent: parent }
          else
            { number: nil, name: base, parent: nil }
          end
        end

        # Extract parent number from a hierarchical phase number.
        #
        # @param number [String] Phase number (e.g., "010.01")
        # @return [String, nil] Parent number or nil for top-level
        def self.extract_parent_from_number(number)
          return nil if number.nil?

          parts = number.split(".")
          return nil if parts.length <= 1

          parts[0..-2].join(".")
        end

        # Generate phase filename from number and name
        #
        # @param number [String] Phase number
        # @param name [String] Phase name
        # @return [String] Phase filename with .ph.md extension
        def self.generate_filename(number, name)
          # Sanitize name for filename
          safe_name = name.to_s.downcase.gsub(/[^a-z0-9]+/, "-").gsub(/^-|-$/, "")
          "#{number}-#{safe_name}.ph.md"
        end

        # Generate report filename from number and name
        #
        # @param number [String] Phase number
        # @param name [String] Phase name
        # @return [String] Report filename with .r.md extension
        def self.generate_report_filename(number, name)
          # Sanitize name for filename
          safe_name = name.to_s.downcase.gsub(/[^a-z0-9]+/, "-").gsub(/^-|-$/, "")
          "#{number}-#{safe_name}.r.md"
        end

        private

        def self.validate_context!(context)
          return if context.nil?

          valid_contexts = Ace::Assign::Models::Phase::VALID_CONTEXTS
          return if valid_contexts.include?(context)

          raise ArgumentError, "Invalid context '#{context}'. Valid values: #{valid_contexts.join(', ')}"
        end
        private_class_method :validate_context!

        def self.parse_time(value)
          return nil if value.nil?
          return value if value.is_a?(Time)

          Time.parse(value.to_s)
        rescue ArgumentError
          nil
        end
        private_class_method :parse_time

        def self.parse_integer(value)
          return nil if value.nil?

          Integer(value)
        rescue ArgumentError, TypeError
          nil
        end
        private_class_method :parse_integer

        def self.parse_integer_array(value)
          return [] if value.nil?

          Array(value).map { |v| parse_integer(v) }.compact.uniq.sort
        end
        private_class_method :parse_integer_array

        def self.parse_boolean(value)
          return nil if value.nil?
          return value if value == true || value == false

          normalized = value.to_s.strip.downcase
          return true if %w[true yes 1].include?(normalized)
          return false if %w[false no 0].include?(normalized)

          nil
        end
        private_class_method :parse_boolean

        def self.parse_positive_integer(value)
          parsed = parse_integer(value)
          return nil if parsed.nil? || parsed <= 0

          parsed
        end
        private_class_method :parse_positive_integer

        def self.parse_non_negative_integer(value)
          parsed = parse_integer(value)
          return nil if parsed.nil? || parsed.negative?

          parsed
        end
        private_class_method :parse_non_negative_integer
      end
    end
  end
end

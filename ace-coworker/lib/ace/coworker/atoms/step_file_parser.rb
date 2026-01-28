# frozen_string_literal: true

require "yaml"

module Ace
  module Coworker
    module Atoms
      # Pure functions for parsing step markdown files.
      #
      # Step files have frontmatter + body structure:
      # ---
      # name: step-name
      # status: pending
      # ---
      # # Instructions
      # ...
      module StepFileParser
        FRONTMATTER_REGEX = /\A---\s*\n(.*?)\n---\s*\n/m

        # Parse step file content into structured data
        #
        # @param content [String] File content with frontmatter + body
        # @return [Hash] Parsed data with :frontmatter and :body keys
        #
        # @example
        #   parse("---\nname: foo\n---\n# Instructions\nDo stuff")
        #   # => { frontmatter: { "name" => "foo" }, body: "# Instructions\nDo stuff" }
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

          {
            name: fm["name"],
            status: (fm["status"] || "pending").to_sym,
            started_at: parse_time(fm["started_at"]),
            completed_at: parse_time(fm["completed_at"]),
            error: fm["error"],
            added_by: fm["added_by"],
            parent: fm["parent"],
            instructions: extract_instructions(body),
            report: extract_report(body)
          }
        end

        # Extract instructions section from body
        # Instructions are everything before the "---" separator (if present)
        # or the entire body if no Report section exists
        #
        # @param body [String] File body after frontmatter
        # @return [String] Instructions content
        def self.extract_instructions(body)
          # Look for Report section
          if body.include?("\n---\n")
            # Everything before the separator
            body.split("\n---\n", 2).first.strip
          else
            body.strip
          end
        end

        # Extract report section from body
        # Report is everything after "---" separator and "# Report" header
        #
        # @param body [String] File body after frontmatter
        # @return [String, nil] Report content or nil
        def self.extract_report(body)
          return nil unless body.include?("\n---\n")

          parts = body.split("\n---\n", 2)
          return nil if parts.size < 2

          report_section = parts[1].strip

          # Remove "# Report" header if present
          if report_section.start_with?("# Report")
            report_section.sub(/^#\s*Report\s*\n+/, "").strip
          else
            report_section.strip
          end
        end

        # Parse filename to extract number and name
        #
        # @param filename [String] Filename like "010-init-project.md"
        # @return [Hash] Extracted number and name
        #
        # @example
        #   parse_filename("010-init-project.md")
        #   # => { number: "010", name: "init-project" }
        #   parse_filename("010.01-setup-dirs.md")
        #   # => { number: "010.01", name: "setup-dirs" }
        def self.parse_filename(filename)
          # Remove .md extension
          base = filename.sub(/\.md$/, "")

          # Match number pattern (with optional dot-separated parts) and name
          match = base.match(/^([\d.]+)-(.+)$/)

          if match
            { number: match[1], name: match[2] }
          else
            { number: nil, name: base }
          end
        end

        # Generate filename from number and name
        #
        # @param number [String] Step number
        # @param name [String] Step name
        # @return [String] Filename
        def self.generate_filename(number, name)
          # Sanitize name for filename
          safe_name = name.to_s.downcase.gsub(/[^a-z0-9]+/, "-").gsub(/^-|-$/, "")
          "#{number}-#{safe_name}.md"
        end

        private

        def self.parse_time(value)
          return nil if value.nil?
          return value if value.is_a?(Time)

          Time.parse(value.to_s)
        rescue ArgumentError
          nil
        end
        private_class_method :parse_time
      end
    end
  end
end

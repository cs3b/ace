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

          context = fm["context"]
          validate_context!(context)

          {
            name: fm["name"],
            status: (fm["status"] || "pending").to_sym,
            skill: fm["skill"],
            context: context, # "fork" triggers Task tool execution
            started_at: parse_time(fm["started_at"]),
            completed_at: parse_time(fm["completed_at"]),
            error: fm["error"],
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

        # Parse filename to extract number and name
        #
        # @param filename [String] Filename like "010-init-project.j.md" or "010-init-project.r.md"
        # @return [Hash] Extracted number and name
        #
        # @example
        #   parse_filename("010-init-project.j.md")
        #   # => { number: "010", name: "init-project" }
        #   parse_filename("010.01-setup-dirs.j.md")
        #   # => { number: "010.01", name: "setup-dirs" }
        def self.parse_filename(filename)
          # Remove .j.md or .r.md extension
          base = filename.sub(/\.[jr]\.md$/, "")

          # Match number pattern (with optional dot-separated parts) and name
          match = base.match(/^([\d.]+)-(.+)$/)

          if match
            { number: match[1], name: match[2] }
          else
            { number: nil, name: base }
          end
        end

        # Generate job filename from number and name
        #
        # @param number [String] Step number
        # @param name [String] Step name
        # @return [String] Job filename with .j.md extension
        def self.generate_filename(number, name)
          # Sanitize name for filename
          safe_name = name.to_s.downcase.gsub(/[^a-z0-9]+/, "-").gsub(/^-|-$/, "")
          "#{number}-#{safe_name}.j.md"
        end

        # Generate report filename from number and name
        #
        # @param number [String] Step number
        # @param name [String] Step name
        # @return [String] Report filename with .r.md extension
        def self.generate_report_filename(number, name)
          # Sanitize name for filename
          safe_name = name.to_s.downcase.gsub(/[^a-z0-9]+/, "-").gsub(/^-|-$/, "")
          "#{number}-#{safe_name}.r.md"
        end

        private

        def self.validate_context!(context)
          return if context.nil?

          valid_contexts = Ace::Coworker::Models::Step::VALID_CONTEXTS
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
      end
    end
  end
end

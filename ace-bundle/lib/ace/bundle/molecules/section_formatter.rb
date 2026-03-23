# frozen_string_literal: true

module Ace
  module Bundle
    module Molecules
      # Formats sections with XML-style tags for different output formats
      class SectionFormatter
        def initialize(format = "markdown-xml")
          @format = format
        end

        # Formats bundle data with sections
        # @param bundle_data [BundleData] bundle data with sections
        # @return [String] formatted output
        def format_with_sections(bundle_data)
          if bundle_data.has_sections?
            format_sections_output(bundle_data)
          else
            # Fallback to regular formatting
            format_legacy_output(bundle_data)
          end
        end

        # Formats only the sections part (for inclusion in larger documents)
        # @param sections [Hash] sections hash
        # @return [String] formatted sections
        def format_sections_only(sections)
          return "" if sections.nil? || sections.empty?

          sorted_sections = sections.sort_by { |name, data| data[:priority] || data["priority"] || 999 }

          case @format
          when "markdown-xml"
            format_sections_markdown_xml(sorted_sections)
          when "markdown"
            format_sections_markdown(sorted_sections)
          when "yaml"
            format_sections_yaml(sorted_sections)
          when "json"
            format_sections_json(sorted_sections)
          else
            format_sections_markdown_xml(sorted_sections)
          end
        end

        private

        # Formats bundle data with sections based on format
        def format_sections_output(bundle_data)
          case @format
          when "markdown-xml"
            format_sections_markdown_xml_full(bundle_data)
          when "markdown"
            format_sections_markdown_full(bundle_data)
          when "yaml"
            format_sections_yaml_full(bundle_data)
          when "json"
            format_sections_json_full(bundle_data)
          else
            format_sections_markdown_xml_full(bundle_data)
          end
        end

        # Formats full bundle data with sections in markdown-xml format
        def format_sections_markdown_xml_full(bundle_data)
          output = []

          # Add any additional content FIRST (before sections)
          if bundle_data.content && !bundle_data.content.empty?
            output << bundle_data.content
            output << ""  # Empty line after content
          end

          # Add sections with XML tags
          output << format_sections_markdown_xml(bundle_data.sorted_sections)

          output.join("\n")
        end

        # Formats sections in markdown-xml format with XML tags
        def format_sections_markdown_xml(sections)
          output = []

          sections.each do |name, section_data|
            title = section_data[:title] || section_data["title"] || name.to_s.humanize
            output << "# #{title}"

            # Add description as plain paragraph if present
            description = section_data[:description] || section_data["description"]
            output << description if description && !description.empty?

            output << "<#{name}>"

            # Format all content types that are present in the section
            if has_files_content?(section_data)
              output << format_files_section(section_data)
            end

            if has_commands_content?(section_data)
              output << format_commands_section(section_data)
            end

            if has_diffs_content?(section_data)
              output << format_diffs_section(section_data)
            end

            if has_content_content?(section_data)
              output << format_content_section(section_data)
            end

            output << "</#{name}>"
            output << ""  # Empty line between sections
          end

          output.join("\n")
        end

        # Formats files section with XML file tags
        def format_files_section(section_data)
          output = []

          files = section_data[:_processed_files] || section_data["_processed_files"] || []
          files.each do |file_info|
            language = detect_language(file_info[:path])
            output << "  <file path=\"#{file_info[:path]}\" language=\"#{language}\">"
            output << format_file_content(file_info[:content])
            output << "  </file>"
          end

          output.join("\n")
        end

        # Formats commands section with output tags
        def format_commands_section(section_data)
          output = []

          commands = section_data[:_processed_commands] || section_data["_processed_commands"] || []
          commands.each do |command_data|
            output << "  <output command=\"#{command_data[:command]}\">"
            output << format_command_output(command_data[:output])
            output << "  </output>"
          end

          output.join("\n")
        end

        # Formats diffs section with output tags
        def format_diffs_section(section_data)
          output = []

          diffs = section_data[:_processed_diffs] || section_data["_processed_diffs"] || []
          diffs.each do |diff_data|
            command = diff_command_for(diff_data)
            output << "  <output command=\"#{command}\">"
            output << format_diff_output(diff_data[:output])
            output << "  </output>"
          end

          output.join("\n")
        end

        # Returns the appropriate command string for a diff based on its source
        def diff_command_for(diff_data)
          source = diff_data[:source] || diff_data["source"]
          range = diff_data[:range] || diff_data["range"]

          case source
          when :pr, "pr"
            "gh pr diff #{range.to_s.sub(/^pr:/, "")}"
          else
            "git diff #{range}"
          end
        end

        # Formats inline content section
        def format_content_section(section_data)
          content = section_data[:_processed_content] || section_data["_processed_content"] || ""
          format_inline_content(content)
        end

        # Formats full bundle data with sections in markdown format
        def format_sections_markdown_full(bundle_data)
          output = []

          # Add any additional content FIRST (before sections)
          if bundle_data.content && !bundle_data.content.empty?
            output << bundle_data.content
            output << ""  # Empty line after content
          end

          # Add sections without XML tags
          output << format_sections_markdown(bundle_data.sorted_sections)

          output.join("\n")
        end

        # Formats sections in markdown format (no XML tags)
        def format_sections_markdown(sections)
          output = []

          sections.each do |name, section_data|
            title = section_data[:title] || section_data["title"] || name.to_s.humanize
            output << "# #{title}"

            # Add description as plain paragraph if present
            description = section_data[:description] || section_data["description"]
            output << description if description && !description.empty?

            # Format all content types that are present in the section
            if has_files_content?(section_data)
              output << format_files_section_markdown(section_data)
            end

            if has_commands_content?(section_data)
              output << format_commands_section_markdown(section_data)
            end

            if has_diffs_content?(section_data)
              output << format_diffs_section_markdown(section_data)
            end

            if has_content_content?(section_data)
              output << format_content_section_markdown(section_data)
            end

            output << ""  # Empty line between sections
          end

          output.join("\n")
        end

        # Formats files section in markdown format
        def format_files_section_markdown(section_data)
          output = []

          files = section_data[:_processed_files] || section_data["_processed_files"] || []
          files.each do |file_info|
            language = detect_language(file_info[:path])
            output << "### #{file_info[:path]}"
            output << "```#{language}"
            output << file_info[:content]
            output << "```"
            output << ""
          end

          output.join("\n")
        end

        # Formats commands section in markdown format
        def format_commands_section_markdown(section_data)
          output = []

          commands = section_data[:_processed_commands] || section_data["_processed_commands"] || []
          commands.each do |command_data|
            output << "### Command: `#{command_data[:command]}`"
            output << "```"
            output << command_data[:output]
            output << "```"
            output << ""
          end

          output.join("\n")
        end

        # Formats diffs section in markdown format
        def format_diffs_section_markdown(section_data)
          output = []

          diffs = section_data[:_processed_diffs] || section_data["_processed_diffs"] || []
          diffs.each do |diff_data|
            output << "### Diff: `#{diff_data[:range]}`"
            output << "```diff"
            output << diff_data[:output]
            output << "```"
            output << ""
          end

          output.join("\n")
        end

        # Formats content section in markdown format
        def format_content_section_markdown(section_data)
          section_data[:_processed_content] || section_data["_processed_content"] || ""
        end

        # Formats sections in YAML format
        def format_sections_yaml(sections)
          require "yaml"

          yaml_data = {}
          sections.each do |name, section_data|
            yaml_data[name] = {
              "title" => section_data[:title] || section_data["title"],
              "content_type" => section_data[:content_type] || section_data["content_type"],
              "priority" => section_data[:priority] || section_data["priority"]
            }

            # Add processed content
            case section_data[:content_type] || section_data["content_type"]
            when "files"
              yaml_data[name]["files"] = format_files_for_yaml(section_data)
            when "commands"
              yaml_data[name]["commands"] = format_commands_for_yaml(section_data)
            when "diffs"
              yaml_data[name]["diffs"] = format_diffs_for_yaml(section_data)
            when "content"
              yaml_data[name]["content"] = section_data[:_processed_content] || section_data["_processed_content"]
            end
          end

          YAML.dump({"sections" => yaml_data})
        end

        # Formats full bundle data in YAML format
        def format_sections_yaml_full(bundle_data)
          require "yaml"

          yaml_data = {
            "preset_name" => bundle_data.preset_name,
            "sections" => format_sections_for_yaml(bundle_data.sections),
            "metadata" => bundle_data.metadata
          }

          if bundle_data.content && !bundle_data.content.empty?
            yaml_data["content"] = bundle_data.content
          end

          YAML.dump(yaml_data)
        end

        # Formats sections in JSON format
        def format_sections_json(sections)
          json_data = {}
          sections.each do |name, section_data|
            json_data[name] = {
              "title" => section_data[:title] || section_data["title"],
              "content_type" => section_data[:content_type] || section_data["content_type"],
              "priority" => section_data[:priority] || section_data["priority"]
            }

            # Add processed content
            case section_data[:content_type] || section_data["content_type"]
            when "files"
              json_data[name]["files"] = format_files_for_json(section_data)
            when "commands"
              json_data[name]["commands"] = format_commands_for_json(section_data)
            when "diffs"
              json_data[name]["diffs"] = format_diffs_for_json(section_data)
            when "content"
              json_data[name]["content"] = section_data[:_processed_content] || section_data["_processed_content"]
            end
          end

          JSON.pretty_generate({"sections" => json_data})
        end

        # Formats full bundle data in JSON format
        def format_sections_json_full(bundle_data)
          require "json"

          json_data = {
            "preset_name" => bundle_data.preset_name,
            "sections" => format_sections_for_json(bundle_data.sections),
            "metadata" => bundle_data.metadata
          }

          if bundle_data.content && !bundle_data.content.empty?
            json_data["content"] = bundle_data.content
          end

          JSON.pretty_generate(json_data)
        end

        # Fallback formatting for non-section bundle data
        def format_legacy_output(bundle_data)
          # Use ace-core OutputFormatter as fallback
          require "ace/core/molecules/output_formatter"
          formatter = Ace::Core::Molecules::OutputFormatter.new(@format)

          data = {
            files: bundle_data.files,
            metadata: bundle_data.metadata,
            commands: bundle_data.commands,
            content: bundle_data.content
          }

          formatter.format(data)
        end

        # Helper methods for formatting specific content types

        def format_files_for_yaml(section_data)
          files = section_data[:_processed_files] || section_data["_processed_files"] || []
          files.map { |f| {"path" => f[:path], "content" => f[:content]} }
        end

        def format_commands_for_yaml(section_data)
          commands = section_data[:_processed_commands] || section_data["_processed_commands"] || []
          commands.map { |c| {"command" => c[:command], "output" => c[:output]} }
        end

        def format_diffs_for_yaml(section_data)
          diffs = section_data[:_processed_diffs] || section_data["_processed_diffs"] || []
          diffs.map { |d| {"range" => d[:range], "output" => d[:output]} }
        end

        def format_files_for_json(section_data)
          format_files_for_yaml(section_data)
        end

        def format_commands_for_json(section_data)
          format_commands_for_yaml(section_data)
        end

        def format_diffs_for_json(section_data)
          format_diffs_for_yaml(section_data)
        end

        def format_sections_for_yaml(sections)
          return {} if sections.nil? || sections.empty?

          yaml_sections = {}
          sections.each do |name, section_data|
            yaml_sections[name] = {
              "title" => section_data[:title] || section_data["title"],
              "content_type" => section_data[:content_type] || section_data["content_type"],
              "priority" => section_data[:priority] || section_data["priority"]
            }

            # Add processed content
            case section_data[:content_type] || section_data["content_type"]
            when "files"
              yaml_sections[name]["files"] = format_files_for_yaml(section_data)
            when "commands"
              yaml_sections[name]["commands"] = format_commands_for_yaml(section_data)
            when "diffs"
              yaml_sections[name]["diffs"] = format_diffs_for_yaml(section_data)
            when "content"
              yaml_sections[name]["content"] = section_data[:_processed_content] || section_data["_processed_content"]
            end
          end
          yaml_sections
        end

        def format_sections_for_json(sections)
          return {} if sections.nil? || sections.empty?

          json_sections = {}
          sections.each do |name, section_data|
            json_sections[name] = {
              "title" => section_data[:title] || section_data["title"],
              "content_type" => section_data[:content_type] || section_data["content_type"],
              "priority" => section_data[:priority] || section_data["priority"]
            }

            # Add processed content
            case section_data[:content_type] || section_data["content_type"]
            when "files"
              json_sections[name]["files"] = format_files_for_json(section_data)
            when "commands"
              json_sections[name]["commands"] = format_commands_for_json(section_data)
            when "diffs"
              json_sections[name]["diffs"] = format_diffs_for_json(section_data)
            when "content"
              json_sections[name]["content"] = section_data[:_processed_content] || section_data["_processed_content"]
            end
          end
          json_sections
        end

        # Content formatting helpers
        def format_file_content(content)
          return "" if content.nil? || content.empty?

          # Indent content for XML formatting
          content.lines.map { |line| "    #{line}" }.join.rstrip
        end

        def format_command_output(output)
          return "" if output.nil? || output.empty?

          # Indent output for XML formatting
          output.lines.map { |line| "    #{line}" }.join.rstrip
        end

        def format_diff_output(output)
          return "" if output.nil? || output.empty?

          # Indent diff output for XML formatting
          output.lines.map { |line| "    #{line}" }.join.rstrip
        end

        def format_inline_content(content)
          return "" if content.nil? || content.empty?

          content
        end

        # Language detection for file syntax highlighting
        def detect_language(file_path)
          LANGUAGE_MAP[File.extname(file_path).downcase] || "text"
        end

        # Language mapping for file extensions
        LANGUAGE_MAP = {
          ".rb" => "ruby",
          ".py" => "python",
          ".js" => "javascript",
          ".ts" => "typescript",
          ".jsx" => "jsx",
          ".tsx" => "tsx",
          ".java" => "java",
          ".c" => "c",
          ".cpp" => "cpp",
          ".cc" => "cpp",
          ".cxx" => "cpp",
          ".h" => "c",
          ".hpp" => "cpp",
          ".cs" => "csharp",
          ".php" => "php",
          ".swift" => "swift",
          ".kt" => "kotlin",
          ".go" => "go",
          ".rs" => "rust",
          ".sh" => "bash",
          ".bash" => "bash",
          ".zsh" => "bash",
          ".sql" => "sql",
          ".html" => "html",
          ".htm" => "html",
          ".css" => "css",
          ".scss" => "scss",
          ".sass" => "scss",
          ".less" => "less",
          ".xml" => "xml",
          ".json" => "json",
          ".yaml" => "yaml",
          ".yml" => "yaml",
          ".toml" => "toml",
          ".md" => "markdown",
          ".markdown" => "markdown",
          ".txt" => "text",
          ".dockerfile" => "dockerfile",
          ".gitignore" => "git",
          ".gitattributes" => "git",
          ".env" => "env",
          ".ini" => "ini",
          ".conf" => "apache"
        }.freeze

        # Helper methods to detect content types in sections

        # Checks if section has files content
        def has_files_content?(section_data)
          !!(section_data[:files] || section_data["files"] ||
                section_data[:_processed_files] || section_data["_processed_files"])
        end

        # Checks if section has commands content
        def has_commands_content?(section_data)
          !!(section_data[:commands] || section_data["commands"] ||
                section_data[:_processed_commands] || section_data["_processed_commands"])
        end

        # Checks if section has diffs content
        def has_diffs_content?(section_data)
          !!(section_data[:ranges] || section_data["ranges"] ||
                section_data[:diffs] || section_data["diffs"] ||
                section_data[:_processed_diffs] || section_data["_processed_diffs"])
        end

        # Checks if section has inline content
        def has_content_content?(section_data)
          !!(section_data[:content] || section_data["content"] ||
                section_data[:_processed_content] || section_data["_processed_content"])
        end
      end
    end
  end
end

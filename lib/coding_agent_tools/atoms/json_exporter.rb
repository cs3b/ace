# frozen_string_literal: true

require "json"

module CodingAgentTools::Atoms
  # Atom for exporting data to JSON format
  # Handles JSON serialization for dependency data
  class JsonExporter
    # Convert dependencies hash to JSON-serializable format
    def format_dependencies(dependencies)
      data = {}
      dependencies.each do |file, deps|
        data[file] = {
          references: deps[:refs_to].to_a.sort,
          referenced_by: deps[:refs_from].to_a.sort
        }
      end
      data
    end

    # Export dependencies to JSON file
    def export_to_file(dependencies, filename = "doc-dependencies.json")
      data = format_dependencies(dependencies)
      json_content = JSON.pretty_generate(data)
      File.write(filename, json_content)
      filename
    end

    # Export dependencies to JSON string
    def export_to_string(dependencies)
      data = format_dependencies(dependencies)
      JSON.pretty_generate(data)
    end

    # Export minimal JSON without pretty formatting
    def export_compact(dependencies)
      data = format_dependencies(dependencies)
      JSON.generate(data)
    end
  end
end
# frozen_string_literal: true

module CodingAgentTools::Atoms
  # Atom for writing DOT graph files
  # Handles graph structure and node styling for documentation dependencies
  class DotGraphWriter
    # Generate DOT graph content from dependencies hash
    def generate_dot_content(dependencies)
      lines = []
      lines << 'digraph DocumentDependencies {'
      lines << '  rankdir=LR;'
      lines << '  node [shape=box];'
      lines << ''

      # Add colored nodes based on file type
      dependencies.each_key do |file|
        color = node_color(file)
        lines << "  \"#{file}\" [fillcolor=#{color}, style=filled];"
      end

      lines << ''

      # Add edges
      dependencies.each do |from, deps|
        deps[:refs_to].each do |to|
          lines << "  \"#{from}\" -> \"#{to}\";"
        end
      end

      lines << '}'
      lines.join("\n")
    end

    # Write DOT graph to file
    def write_dot_file(dependencies, filename = 'doc-dependencies.dot')
      content = generate_dot_content(dependencies)
      File.write(filename, content)
      filename
    end

    # Determine node color based on file type
    def node_color(file)
      case file
      when /\.wf\.md$/
        'lightblue'
      when /\.g\.md$/
        'lightgreen'
      when /tasks.*\.md$/
        'lightyellow'
      else
        'lightgray'
      end
    end

    # Generate instructions for creating PNG from DOT file
    def png_generation_instructions(dot_filename)
      png_filename = dot_filename.sub(/\.dot$/, '.png')
      "dot -Tpng #{dot_filename} -o #{png_filename}"
    end
  end
end

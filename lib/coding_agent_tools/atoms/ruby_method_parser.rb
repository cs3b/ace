# frozen_string_literal: true

require "parser/current"

module CodingAgentTools
  module Atoms
    # Parses Ruby files to extract method definitions and their line ranges
    # Uses the Parser gem for accurate AST parsing
    class RubyMethodParser
      class ParseError < StandardError; end

      # Represents a method definition
      MethodDefinition = Struct.new(:name, :start_line, :end_line, :type) do
        def line_range
          start_line..end_line
        end
      end

      def initialize
        # Configure parser to use current Ruby version
        Parser::Builders::Default.emit_lambda = true
        Parser::Builders::Default.emit_procarg0 = true
      end

      # Parses a Ruby file and extracts method definitions
      # @param file_path [String] Path to Ruby file
      # @return [Array<MethodDefinition>] Method definitions with line ranges
      # @raise [ParseError] If file cannot be parsed
      def parse_file(file_path)
        content = read_file_content(file_path)
        parse_content(content, file_path)
      end

      # Parses Ruby source code and extracts method definitions
      # @param content [String] Ruby source code
      # @param source_name [String] Name for error reporting (usually file path)
      # @return [Array<MethodDefinition>] Method definitions with line ranges
      # @raise [ParseError] If content cannot be parsed
      def parse_content(content, source_name = "<string>")
        ast = parse_ast(content, source_name)
        extract_methods(ast)
      end

      private

      def read_file_content(file_path)
        File.read(file_path)
      rescue StandardError => e
        raise ParseError, "Cannot read file #{file_path}: #{e.message}"
      end

      def parse_ast(content, source_name)
        Parser::CurrentRuby.parse(content, source_name)
      rescue Parser::SyntaxError => e
        raise ParseError, "Syntax error in #{source_name}: #{e.message}"
      rescue StandardError => e
        raise ParseError, "Parse error in #{source_name}: #{e.message}"
      end

      def extract_methods(node, methods = [])
        return methods unless node

        case node.type
        when :def
          methods << extract_instance_method(node)
        when :defs
          methods << extract_class_method(node)
        when :class, :module
          # Recursively search inside classes and modules
          node.children.each { |child| extract_methods(child, methods) }
        else
          # Search all children for nested methods
          if node.respond_to?(:children) && node.children
            node.children.each do |child|
              extract_methods(child, methods) if child.is_a?(Parser::AST::Node)
            end
          end
        end

        methods
      end

      def extract_instance_method(node)
        name = node.children[0].to_s
        location = node.location
        
        MethodDefinition.new(
          name: name,
          start_line: location.line,
          end_line: location.last_line,
          type: :def
        )
      end

      def extract_class_method(node)
        name = node.children[1].to_s
        location = node.location
        
        MethodDefinition.new(
          name: "self.#{name}",
          start_line: location.line,
          end_line: location.last_line,
          type: :defs
        )
      end
    end
  end
end
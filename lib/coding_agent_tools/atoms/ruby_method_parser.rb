# frozen_string_literal: true

require "parser/current"

module CodingAgentTools
  module Atoms
    # Parses Ruby files to extract method definitions and their line ranges
    # Uses the Parser gem for accurate AST parsing
    class RubyMethodParser
      class ParseError < StandardError; end

      # Represents a method definition
      MethodDefinition = Struct.new(:name, :start_line, :end_line, :type, :visibility) do
        def line_range
          start_line..end_line
        end

        def public?
          visibility == :public
        end

        def private?
          visibility == :private
        end

        def protected?
          visibility == :protected
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
      rescue => e
        raise ParseError, "Cannot read file #{file_path}: #{e.message}"
      end

      def parse_ast(content, source_name)
        Parser::CurrentRuby.parse(content, source_name)
      rescue Parser::SyntaxError => e
        raise ParseError, "Syntax error in #{source_name}: #{e.message}"
      rescue => e
        raise ParseError, "Parse error in #{source_name}: #{e.message}"
      end

      def extract_methods(node, methods = [], current_visibility = :public)
        return methods unless node

        case node.type
        when :def
          methods << extract_instance_method(node, current_visibility)
        when :defs
          methods << extract_class_method(node, current_visibility)
        when :send
          # Check for visibility modifiers (private, protected, public)
          if visibility_modifier?(node)
            new_visibility = node.children[1]
            # Apply to subsequent methods in this scope
            return extract_methods_with_visibility_change(node, methods, new_visibility)
          else
            # Search children with current visibility
            search_children(node, methods, current_visibility)
          end
        when :class, :module
          # Classes and modules start with public visibility
          search_children(node, methods, :public)
        else
          # Search all children for nested methods
          search_children(node, methods, current_visibility)
        end

        methods
      end

      def extract_instance_method(node, visibility)
        name = node.children[0].to_s
        location = node.location

        MethodDefinition.new(
          name: name,
          start_line: location.line.to_i,
          end_line: location.last_line.to_i,
          type: :def,
          visibility: visibility
        )
      end

      def extract_class_method(node, visibility)
        name = node.children[1].to_s
        location = node.location

        MethodDefinition.new(
          name: "self.#{name}",
          start_line: location.line.to_i,
          end_line: location.last_line.to_i,
          type: :defs,
          visibility: visibility
        )
      end

      def visibility_modifier?(node)
        return false unless node.type == :send
        return false unless node.children[0].nil? # No receiver

        modifier_name = node.children[1]
        [:private, :protected, :public].include?(modifier_name)
      end

      def search_children(node, methods, current_visibility)
        if node.respond_to?(:children) && node.children
          node.children.each do |child|
            extract_methods(child, methods, current_visibility) if child.is_a?(Parser::AST::Node)
          end
        end
      end

      def extract_methods_with_visibility_change(node, methods, new_visibility)
        # This is a simplified approach - in practice, visibility changes
        # affect subsequent method definitions in the same scope
        search_children(node, methods, new_visibility)
        methods
      end
    end
  end
end

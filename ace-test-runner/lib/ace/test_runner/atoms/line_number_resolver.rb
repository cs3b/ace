# frozen_string_literal: true

require "prism"

module Ace
  module TestRunner
    module Atoms
      module LineNumberResolver
        class SelectionError < ArgumentError; end
        module_function

        def parse_file_with_line(selector)
          if (match = /\A(.+\.rb):(.+)\z/.match(selector))
            unless match[2].match?(/\A[1-9]\d*\z/)
              raise SelectionError, "Invalid test selector: #{selector}"
            end
            {file: match[1], line: Integer(match[2], 10)}
          else
            {file: selector, line: nil}
          end
        end

        def resolve_test_at_line(file_path, line_number)
          resolve_identity(file_path, line_number).fetch(:name)
        end

        def resolve_identity(file_path, line_number, source: nil)
          selector = "#{file_path}:#{line_number}"
          source ||= File.read(file_path)
          unless line_number.is_a?(Integer) && line_number.positive? && line_number <= source.lines.size
            raise SelectionError, "Invalid test selector: #{selector}"
          end
          parsed = Prism.parse(source)
          raise SelectionError, "Malformed Ruby in test selector: #{selector}" unless parsed.success?

          declarations = []
          scopes = Hash.new(0)
          collect(parsed.value, [], false, true, declarations, scopes)
          matches = declarations.select { |entry| (entry[:start_line]..entry[:end_line]).cover?(line_number) }
          selected = matches.one? && matches.first
          valid = selected && selected[:supported] && scopes[selected[:class_name]] == 1 &&
            declarations.count { |entry| entry.values_at(:class_name, :name) == selected.values_at(:class_name, :name) } == 1
          raise SelectionError, "Unmatched or ambiguous test selector: #{selector}" unless valid

          selected.reject { |key, _| key == :supported }.merge(file: File.expand_path(file_path)).freeze
        rescue Errno::ENOENT, Errno::EACCES, Errno::EISDIR => error
          raise SelectionError, "Cannot read test selector #{selector}: #{error.class}"
        end

        def collect(node, namespace, in_class, supported, declarations, scopes)
          return unless node
          case node
          when Prism::ProgramNode
            collect(node.statements, namespace, in_class, supported, declarations, scopes)
          when Prism::StatementsNode
            node.body.each { |child| collect(child, namespace, in_class, supported, declarations, scopes) }
          when Prism::ClassNode, Prism::ModuleNode
            text = node.constant_path.location.slice
            static = text.match?(/\A(?:::)?[A-Z]\w*(?:::[A-Z]\w*)*\z/)
            parts = static ? text.delete_prefix("::").split("::") : []
            path = text.start_with?("::") ? parts : namespace + parts
            scopes[path.join("::")] += 1
            collect(node.body, path, node.is_a?(Prism::ClassNode), supported && static, declarations, scopes)
          when Prism::DefNode
            if node.name.to_s.start_with?("test_")
              add_declaration(node, node.name.to_s, namespace, supported && in_class && node.receiver.nil?,
                node.def_keyword_loc.start_line, declarations)
            end
            # Nested declarations cannot acquire the surrounding static class's identity.
            collect(node.body, namespace, in_class, false, declarations, scopes)
          when Prism::CallNode
            if node.name == :test && node.block.is_a?(Prism::BlockNode)
              arguments = node.arguments&.arguments || []
              literal = arguments.one? && arguments.first.is_a?(Prism::StringNode)
              name = literal ? "test_#{arguments.first.unescaped.gsub(/\s+/, '_')}" : nil
              static = supported && in_class && node.receiver.nil? && literal && node.block.opening_loc.slice == "do"
              add_declaration(node, name, namespace, static, node.block.opening_loc.start_line, declarations)
            end
            node.compact_child_nodes.each { |child| collect(child, namespace, in_class, false, declarations, scopes) }
          else
            node.compact_child_nodes.each { |child| collect(child, namespace, in_class, false, declarations, scopes) }
          end
        end

        def add_declaration(node, name, namespace, supported, method_line, declarations)
          declarations << {name: name, class_name: namespace.join("::"), start_line: node.location.start_line,
            end_line: node.location.end_line, method_line: method_line, supported: supported}
        end
        private_class_method :collect, :add_declaration
      end
    end
  end
end

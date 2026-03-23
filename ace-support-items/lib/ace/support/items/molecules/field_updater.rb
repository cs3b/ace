# frozen_string_literal: true

require "fileutils"
require_relative "../atoms/frontmatter_parser"
require_relative "../atoms/frontmatter_serializer"

module Ace
  module Support
    module Items
      module Molecules
        # Orchestrates --set/--add/--remove field updates on frontmatter files.
        # Handles nested dot-key paths for --set operations.
        # Writes atomically using temp file + rename.
        class FieldUpdater
          # Update frontmatter fields in a spec file.
          #
          # @param file_path [String] Path to the spec file
          # @param set [Hash] Fields to set (key => value). Supports dot-notation for nested keys.
          # @param add [Hash] Fields to append to arrays (key => value or array of values).
          # @param remove [Hash] Fields to remove from arrays (key => value or array of values).
          # @return [Hash] Updated frontmatter hash
          def self.update(file_path, set: {}, add: {}, remove: {})
            content = File.read(file_path)
            frontmatter, body = Atoms::FrontmatterParser.parse(content)
            # Strip leading newline from body so rebuild doesn't double-space
            body = body.sub(/\A\n/, "")

            apply_set(frontmatter, set)
            apply_add(frontmatter, add)
            apply_remove(frontmatter, remove)

            new_content = Atoms::FrontmatterSerializer.rebuild(frontmatter, body)
            atomic_write(file_path, new_content)

            frontmatter
          end

          # Apply --set operations (supports nested dot-key paths).
          # @param frontmatter [Hash] Frontmatter hash (mutated in place)
          # @param set [Hash] Key-value pairs to set
          def self.apply_set(frontmatter, set)
            return if set.nil? || set.empty?

            set.each do |key, value|
              key_str = key.to_s
              if key_str.include?(".")
                apply_nested_set(frontmatter, key_str, value)
              else
                frontmatter[key_str] = value
              end
            end
          end

          # Apply --add operations (append to arrays).
          # If the existing value is a scalar, coerces it to an array first.
          # @param frontmatter [Hash] Frontmatter hash (mutated in place)
          # @param add [Hash] Key-value pairs to add
          def self.apply_add(frontmatter, add)
            return if add.nil? || add.empty?

            add.each do |key, value|
              key_str = key.to_s
              current = frontmatter[key_str]
              values_to_add = Array(value)

              frontmatter[key_str] = (Array(current) + values_to_add).uniq
            end
          end

          # Apply --remove operations (remove from arrays).
          # @param frontmatter [Hash] Frontmatter hash (mutated in place)
          # @param remove [Hash] Key-value pairs to remove
          # @raise [ArgumentError] If target field is not an array
          def self.apply_remove(frontmatter, remove)
            return if remove.nil? || remove.empty?

            remove.each do |key, value|
              key_str = key.to_s
              current = frontmatter[key_str]
              next if current.nil?

              unless current.is_a?(Array)
                raise ArgumentError, "Cannot remove from non-array field '#{key_str}' (is #{current.class})"
              end

              values_to_remove = Array(value)
              frontmatter[key_str] = current - values_to_remove
            end
          end

          # Navigate nested dot-key path and set value.
          # "update.last-updated" => frontmatter["update"]["last-updated"] = value
          def self.apply_nested_set(frontmatter, key_path, value)
            parts = key_path.split(".")
            target = frontmatter

            parts[0...-1].each do |part|
              target[part] ||= {}
              target = target[part]
            end

            target[parts.last] = value
          end

          # Write content atomically using temp file + rename.
          def self.atomic_write(file_path, content)
            tmp_path = "#{file_path}.tmp.#{Process.pid}"
            File.write(tmp_path, content)
            File.rename(tmp_path, file_path)
          rescue
            File.unlink(tmp_path) if tmp_path && File.exist?(tmp_path)
            raise
          end

          private_class_method :apply_nested_set, :atomic_write
        end
      end
    end
  end
end

# frozen_string_literal: true
require_relative "protected_artifact_set"
require "rbconfig"

module Ace
  module Runtime
    module Molecules
      # The private hook installs this guard before loading its ACE dependencies.
      # Every executable file is verified before require can evaluate it.
      class ReadinessRuntime
        BUILTINS = %w[enumerator.so thread.rb fiber.so rational.so complex.so ruby2_keywords.rb].freeze

        def initialize(configuration:, artifacts: ProtectedArtifactSet.new)
          @runtime, @artifacts = configuration.fetch("runtime"), artifacts
          @references = @runtime.fetch("dependencies").to_h { |ref| [ref.fetch("path"), ref] }.freeze
        end

        def activate!(features: $LOADED_FEATURES, load_paths: $LOAD_PATH)
          verify_loaded!(features)
          @runtime.fetch("load_paths").each do |path|
            ProtectedSocket.root_path!(path, directory: true)
          end
          load_paths.replace(@runtime.fetch("load_paths"))
          owner = self
          guard = Module.new do
            define_method(:require) do |feature|
              path = owner.resolve!(feature)
              owner.verify_file!(path)
              super(path)
            end
            define_method(:require_relative) do |feature|
              caller_file = caller_locations(1, 1).first.absolute_path
              path = owner.resolve!(File.expand_path(feature, File.dirname(caller_file)))
              owner.verify_file!(path)
              require(path)
            end
            private :require, :require_relative
          end
          Kernel.prepend(guard)
          true
        end

        def verify_loaded!(features)
          features.each do |feature|
            next if BUILTINS.include?(feature)
            unless feature.is_a?(String) && feature.start_with?("/") && @references.key?(feature)
              raise RuntimeUnavailableError, "readiness startup loaded undeclared code"
            end
            verify_file!(feature)
          end
          true
        end

        def resolve!(feature)
          unless feature.is_a?(String) && !feature.include?("\0")
            raise RuntimeUnavailableError, "readiness require selection differs"
          end
          bases = feature.start_with?("/") ? [feature] : @runtime.fetch("load_paths").map { |path| File.join(path, feature) }
          extension = "." + RbConfig::CONFIG.fetch("DLEXT")
          candidates = bases.flat_map do |path|
            # Ruby maps explicit .so/.o requests to its own platform extension.
            if path.end_with?(".so", ".o")
              [path.sub(/\.(?:so|o)\z/, extension)]
            elsif path.end_with?(".rb", extension)
              [path]
            else
              [path, path + ".rb", path + extension]
            end
          end
          selected = candidates.find { |path| @references.key?(path) }
          raise RuntimeUnavailableError, "readiness require is outside protected closure" unless selected
          selected
        end

        def verify_file!(path)
          @artifacts.with do |reader|
            reader.read!(@references.fetch(path))
            reader.verify_unchanged!
          end
          true
        end
      end
    end
  end
end

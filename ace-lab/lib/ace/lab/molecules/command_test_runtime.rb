# frozen_string_literal: true

require "json"
require "digest"
require "find"
require_relative "grant_resolver"

module Ace
  module Lab
    module Molecules
      # Data-only installed runtime recipe. Candidate gemspecs are evaluated by
      # Bundler only in the dropped executor, never by this root-side compiler.
      class CommandTestRuntime
        GEM_NAME = /\A[a-zA-Z0-9][a-zA-Z0-9_.-]{0,127}\z/
        VERSION = /\A[0-9][a-zA-Z0-9_.-]{0,63}\z/
        SHA = /\A[0-9a-f]{64}\z/

        def self.load(recipe)
          bytes = GrantResolver.read_verified(recipe.fetch("runtime_path"))
          unless bytes && bytes.bytesize <= 65_536 && Digest::SHA256.hexdigest(bytes) == recipe.fetch("runtime_sha256")
            raise InvalidConfigurationError, "selected test runtime differs or is unavailable"
          end
          new(JSON.parse(bytes, allow_duplicate_key: false, create_additions: false, max_nesting: 16))
        rescue JSON::ParserError
          raise InvalidConfigurationError, "selected test runtime is invalid"
        end

        def initialize(document)
          document = @document = JSON.parse(JSON.generate(document))
          strict!(document, %w[schema gem_paths gems source_gems package argv executable_sha256 entrypoint_sha256])
          invalid! unless document["schema"] == "ruby-test-runtime/v1" &&
            document["gem_paths"].is_a?(Array) && document["gem_paths"].size.between?(1, 8) &&
            document["gem_paths"].uniq == document["gem_paths"] && document["gem_paths"].all? { |path| absolute?(path) } &&
            document["gems"].is_a?(Hash) && document["gems"].size.between?(1, 128) &&
            document["source_gems"].is_a?(Hash) && document["source_gems"].size.between?(1, 64)
          document.fetch("gems").each do |name, gem|
            strict!(gem, %w[version sha256])
            invalid! unless name.is_a?(String) && GEM_NAME.match?(name) && gem["version"].is_a?(String) &&
              VERSION.match?(gem["version"]) && gem["sha256"].is_a?(String) && SHA.match?(gem["sha256"])
          end
          invalid! unless document.fetch("source_gems").all? { |name, path| name.is_a?(String) && GEM_NAME.match?(name) && relative?(path) } &&
            (document.fetch("gems").keys & document.fetch("source_gems").keys).empty? &&
            document.fetch("source_gems").values.include?(document["package"])
          argv = document["argv"]
          invalid! unless argv.is_a?(Array) && argv.size.between?(6, 128) && argv.all? { |item|
            item.is_a?(String) && item.bytesize <= 4096 && !item.include?("\0") } &&
            absolute?(argv[0]) && absolute?(argv[1]) && argv.count("@configuration") == 1 && argv.count("@output") == 1 &&
            argv.count("--config-path") == 1 && argv.count("--report-dir") == 1 &&
            argv.each_cons(2).any? { |pair| pair == ["--config-path", "@configuration"] } &&
            argv.each_cons(2).any? { |pair| pair == ["--report-dir", "@output"] } &&
            %w[executable_sha256 entrypoint_sha256].all? { |key| document[key].is_a?(String) && SHA.match?(document[key]) }
        end

        def compile(definition:, execution_id:, candidate:)
          invalid! unless execution_id.is_a?(String) && CommandPolicy::ID.match?(execution_id)
          recipe = definition.fetch("source")
          root = File.join(recipe.fetch("root"), execution_id)
          source = File.join(root, "source")
          config = File.join(root, "config")
          output = File.join(root, "output")
          environment = definition.fetch("executor").fetch("environment")
          invalid! unless (environment.keys & %w[TMPDIR TMP TEMP XDG_CACHE_HOME]).empty?
          replacements = {"@configuration" => File.join(config, "runner.json"), "@output" => File.join(output, "reports")}
          argv = @document.fetch("argv").map { |item| replacements.fetch(item, item) }
          # RubyGems binstubs do not activate BUNDLE_GEMFILE themselves. Pin the
          # generated closure before the public runner loads any package code.
          argv.insert(1, "-rbundler/setup")
          invalid! if JSON.generate(argv).bytesize > 2048
          invalid! unless definition.fetch("executable_sha256") == @document.fetch("executable_sha256")
          result = definition.merge("argv" => argv, "source" => candidate.slice("head", "tree"),
            "candidate" => candidate, "materialization" => recipe.merge("execution_id" => execution_id),
            "executor" => definition.fetch("executor").merge("cwd" => File.join(source, @document.fetch("package")),
              "environment" => environment.merge(runtime_environment(root))))
          invalid! if JSON.generate(result).bytesize > 8192
          result
        end

        def runtime_environment(root)
          {"GEM_HOME" => @document.fetch("gem_paths").first,
            "GEM_PATH" => @document.fetch("gem_paths").join(File::PATH_SEPARATOR),
            "BUNDLE_GEMFILE" => File.join(root, "config", "Gemfile"),
            "BUNDLE_USER_HOME" => File.join(root, "output", "bundle"),
            "BUNDLE_IGNORE_CONFIG" => "true", "BUNDLE_AUTO_INSTALL" => "false", "BUNDLE_VERSION" => "system",
            "RUBYOPT" => "-rbundler/setup",
            "TMPDIR" => File.join(root, "output", "tmp"), "XDG_CACHE_HOME" => File.join(root, "output", "cache")}
        end

        def configuration(root)
          JSON.generate("environment" => {"overrides" => runtime_environment(root)}) + "\n"
        end

        def gemfile(root)
          lines = ['source "https://rubygems.org"']
          @document.fetch("gems").sort.each { |name, gem| lines << "gem #{name.dump}, #{("= " + gem.fetch('version')).dump}" }
          @document.fetch("source_gems").sort.each { |name, path|
            lines << "gem #{name.dump}, path: #{File.join(root, 'source', path).dump}" }
          lines.join("\n") + "\n"
        end

        def verify_installed!(deadline: Process.clock_gettime(Process::CLOCK_MONOTONIC) + 10)
          @document.fetch("gem_paths").each do |path|
            GrantResolver.trusted_directory!(path)
            canonical = File.realpath(path)
            count = 0
            Find.find(path, ignore_error: false) do |entry|
              if (count += 1) > 100_000 || Process.clock_gettime(Process::CLOCK_MONOTONIC) >= deadline
                raise InvalidConfigurationError, "selected test runtime exceeds verification bound"
              end
              stat = File.lstat(entry)
              alias_ok = stat.symlink? && File.realpath(entry).start_with?(canonical + "/")
              unless stat.uid.zero? && (alias_ok || (!stat.symlink? && (stat.mode & 0o022).zero? && (stat.directory? || stat.file?)))
                raise InvalidConfigurationError, "selected installed test runtime is writable or untrusted"
              end
            end
            %w[specifications cache gems].each do |kind|
              directory = File.join(path, kind)
              raise InvalidConfigurationError, "selected test runtime inventory is missing" unless File.directory?(directory)
              Dir.children(directory).each do |file|
                basename = case kind
                when "specifications" then file.delete_suffix(".gemspec") if file.end_with?(".gemspec")
                when "cache" then file.delete_suffix(".gem") if file.end_with?(".gem")
                else file
                end
                unless basename && declared_installed_name?(basename)
                  raise InvalidConfigurationError, "selected test runtime contains undeclared installed gems"
                end
              end
            end
          end
          @document.fetch("gems").each do |name, gem|
            matches = @document.fetch("gem_paths").select { |path|
              archive = File.join(path, "cache", "#{name}-#{gem.fetch('version')}.gem")
              bytes = GrantResolver.read_verified(archive)
              bytes && Digest::SHA256.hexdigest(bytes) == gem.fetch("sha256") &&
                GrantResolver.read_verified(File.join(path, "specifications", "#{name}-#{gem.fetch('version')}.gemspec")) }
            raise InvalidConfigurationError, "selected installed test dependency is unavailable" unless matches.size == 1
          end
          %w[executable_sha256 entrypoint_sha256].each_with_index do |key, index|
            path = @document.fetch("argv").fetch(index)
            bytes = GrantResolver.read_verified(path)
            unless bytes && Digest::SHA256.hexdigest(bytes) == @document.fetch(key) && File.executable?(path)
              raise InvalidConfigurationError, "selected test runtime executable differs"
            end
          end
          true
        rescue SystemCallError
          raise InvalidConfigurationError, "selected installed test runtime is not fully observable"
        end

        private

        def declared_installed_name?(basename)
          @document.fetch("gems").any? { |name, gem| basename == "#{name}-#{gem.fetch('version')}" } ||
            @document.fetch("source_gems").keys.any? { |name|
              basename.start_with?("#{name}-") && VERSION.match?(basename.delete_prefix("#{name}-")) }
        end

        def absolute?(value) = value.is_a?(String) && value.start_with?("/") && !value.include?("\0") && File.expand_path(value) == value
        def relative?(value) = value.is_a?(String) && !value.empty? && !value.start_with?("/") && !value.include?("\0") &&
          value.split("/", -1).none? { |part| part.empty? || %w[. .. .git].include?(part.downcase) }
        def strict!(value, keys)
          invalid! unless value.is_a?(Hash) && value.keys.sort == keys.sort
        end
        def invalid! = raise(InvalidConfigurationError, "invalid selected test runtime profile")
      end
    end
  end
end

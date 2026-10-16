# frozen_string_literal: true
require "digest"
require "fileutils"
require "securerandom"
require "uri"
module Ace
  module Design
    module Molecules
      module Artifacts
        module_function
        def write(path, value)
          raise Error, "Refusing symlink: #{path}" if File.symlink?(path)
          temporary = "#{path}.#{SecureRandom.hex(6)}.tmp"
          File.write(temporary, value)
          File.rename(temporary, path)
        ensure
          File.unlink(temporary) if temporary && File.exist?(temporary)
        end
        def json(path, value)
          write(path, JSON.pretty_generate(value) + "\n")
        end
        def object(path)
          value = JSON.parse(File.read(path))
          Atoms::Contracts.object(value, path)
        rescue JSON::ParserError => e
          raise Error, "Invalid JSON #{path}: #{e.message}"
        end
        def files(root)
          raise Error, "Missing artifact directory: #{root}" unless File.directory?(root) && !File.symlink?(root)
          Dir.glob("**/*", File::FNM_DOTMATCH, base: root).sort.reject { |p| p == "." || p == ".." }.select do |name|
            path = File.join(root, name)
            raise Error, "Symlinks are not design artifacts: #{name}" if File.symlink?(path)
            raise Error, "Unsupported artifact: #{name}" unless File.directory?(path) || File.file?(path)
            File.file?(path)
          end
        end
        def digest(root)
          Digest::SHA256.hexdigest(files(root).map do |name|
            "#{name}\0#{Digest::SHA256.file(File.join(root, name)).hexdigest}\n"
          end.join)
        end
        def descriptor(root)
          file = File.join(root, "artifact.json")
          return {"type" => "html", "entry" => "index.html"} unless File.exist?(file)
          raise Error, "Symlink artifact descriptor" if File.symlink?(file)
          data = object(file)
          type, entry = data.values_at("type", "entry")
          raise Error, "Invalid artifact type" unless %w[html image url].include?(type)
          Atoms::Contracts.text(entry, "artifact entry")
          if type == "url"
            uri = URI.parse(entry)
            raise Error, "Artifact URL must be HTTP(S), without credentials" unless %w[http https].include?(uri.scheme) && uri.host && !uri.userinfo
          else
            target = File.expand_path(entry, root)
            unless target.start_with?(File.expand_path(root) + "/") && File.file?(target) && !File.symlink?(target)
              raise Error, "Artifact entry is missing or escapes variant"
            end
            extension = type == "html" ? /\.html\z/i : /\.(png|jpe?g|webp|gif)\z/i
            raise Error, "Artifact extension does not match type" unless entry.match?(extension)
          end
          data
        rescue URI::InvalidURIError => e
          raise Error, e.message
        end
        def validate_variant(root, types: ["html"], shared_reference: true)
          names = files(root)
          artifact = descriptor(root)
          unless shared_reference
            checks = artifact["checks"]
            unless artifact["status"] == "complete" && checks.is_a?(Array) && !checks.empty? &&
                checks.all? { |check| check.is_a?(Hash) && check["name"].is_a?(String) && check["status"] == "passed" }
              raise Error, "External process incomplete: artifact.json must report complete status and passed required checks"
            end
          end
          raise Error, "Preset does not allow artifact type #{artifact['type']}" unless types.include?(artifact.fetch("type"))
          required = ["direction.md"]
          required << artifact.fetch("entry") unless artifact["type"] == "url"
          required.each do |name|
            unless names.include?(name) && !File.read(File.join(root, name)).strip.empty?
              raise Error, "Variant requires nonempty #{name}"
            end
          end
          if artifact["type"] == "html"
            html = File.read(File.join(root, artifact.fetch("entry")))
            raise Error, "HTML artifact must contain markup" unless html.match?(/<[a-z][^>]*>/i)
          end
          code = names.grep(/\.(?:html|js|mjs)$/).map { |name| File.read(File.join(root, name)) }.join("\n")
          raise Error, "Variant must load ../../fixtures.json" if shared_reference && !code.include?("../../fixtures.json")
          digest(root)
        end
      end
    end
  end
end

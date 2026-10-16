# frozen_string_literal: true
require "uri"
module Ace
  module Design
    module Molecules
      # Resolves provenance without fetching during dry-run; captures once before preparation.
      class DesignSource
        attr_reader :info
        def initialize(reference, config: Design.config)
          @config = config
          @info = if reference.nil?
            nil
          elsif reference.start_with?("session:")
            match = /\Asession:([0-9a-z]+)\/([a-z][a-z0-9_-]{0,31})\z/.match(reference)
            raise Error, "Expected session:TOKEN/VARIANT" unless match
            root = File.expand_path(File.join(config.fetch("run_root"), match[1]))
            session = Session.new(root)
            raise Error, "Source variant is not available" unless session.variants.include?(match[2])
            %w[fixtures.json design.md brief.md].each do |name|
              unless File.file?(File.join(root, name)) && File.readable?(File.join(root, name))
                raise Error, "Source session #{match[1]} is missing readable #{name}; create a new session with complete shared inputs"
              end
            end
            Artifacts.files(File.join(root, "variants", match[2]))
            {"type" => "session", "reference" => reference, "root" => root, "variant" => match[2],
             "surface" => session.metadata.fetch("surface"), "kind" => session.metadata.fetch("kind")}
          elsif reference.match?(/\Ahttps?:\/\//)
            uri = URI.parse(reference)
            raise Error, "Source URL requires a host and no credentials" if !uri.host || uri.userinfo
            {"type" => "url", "reference" => reference}
          else
            file = File.realpath(reference)
            raise Error, "Source must be a PNG, JPEG, WebP or GIF file" unless File.file?(file) && file.match?(/\.(png|jpe?g|webp|gif)\z/i)
            {"type" => "image", "reference" => file}
          end
        rescue SystemCallError, URI::InvalidURIError => e
          raise Error, "Invalid design source: #{e.message}"
        end
        def self.scope(surface:, kind:, profile: nil, source: nil)
          expected = profile ? profile.split("/").first(2) : [source&.dig("surface"), source&.dig("kind")]
          expected[1] = nil unless %w[view component].include?(expected[1])
          [[surface, expected[0], "surface"], [kind, expected[1], "kind"]].each do |explicit, inherited, field|
            raise Error, "Conflicting #{field}: #{explicit} versus #{inherited}" if explicit && inherited && explicit != inherited
          end
          result = [surface || expected[0], kind || expected[1] || "view"]
          Atoms::Contracts.surface(result[0])
          Atoms::Contracts.kind(result[1])
          if source && source["surface"] && result != source.values_at("surface", "kind")
            raise Error, "Source session scope conflicts with the selected profile/task"
          end
          result
        end
        def capture_url(url, target)
          runtime = Runtime.new(@config)
          result = runtime.capture(runtime.node, runtime.script("source.mjs"), runtime.directory, url, target, timeout: 90)
          raise Error, "Source capture failed: #{result['stderr']}" unless result["exit_code"] == 0
        end
        def requirements
          remote = info && (info["type"] == "url" || (info["type"] == "session" &&
            Artifacts.descriptor(File.join(info.fetch("root"), "variants", info.fetch("variant")))["type"] == "url"))
          return [] unless remote
          [{"name" => "Source capture: configured Node, Playwright and Chromium", "status" => "agent_check",
            "check" => "ace-design doctor", "node" => @config.fetch("node"), "runtime_dir" => @config.fetch("runtime_dir")}]
        end
        def snapshot(root)
          return unless info
          target = File.join(root, "source")
          FileUtils.mkdir_p(target)
          case info.fetch("type")
          when "image"
            FileUtils.cp(info.fetch("reference"), File.join(target, "mockup#{File.extname(info.fetch('reference')).downcase}"))
          when "url"
            capture_url(info.fetch("reference"), target)
          when "session"
            source = File.join(info.fetch("root"), "variants", info.fetch("variant"))
            Artifacts.files(source)
            FileUtils.cp_r(source, File.join(target, "variant"))
            artifact = Artifacts.descriptor(source)
            capture_url(artifact.fetch("entry"), target) if artifact["type"] == "url"
            %w[fixtures.json design.md brief.md].each do |name|
              FileUtils.cp(File.join(info.fetch("root"), name), File.join(target, name))
            end
          end
          Artifacts.json(File.join(target, "source.json"), info)
        end
      end
    end
  end
end

# frozen_string_literal: true
require "fileutils"
require "digest"
require "ace/bundle"
require "time"
module Ace
  module Design
    module Organisms
      class Generator
        def initialize(config: Design.config, executor: Molecules::AgentExecutor.new)
          @config, @executor = config, executor
        end
        def generate(surface: nil, prompt: nil, prompt_append: [], intent: "explore", from: nil, preset: "fast", input: [], fixtures: nil, model: nil,
          variant_prompts: [], variant_prompt_files: [], language: nil, dry_run: false, kind: nil, profile: nil)
          raise Error, "Unknown intent: #{intent}" unless %w[explore recreate reimagine].include?(intent)
          raise Error, "explore does not accept --from" if intent == "explore" && from
          raise Error, "#{intent} requires --from" if intent != "explore" && !from
          source = Molecules::DesignSource.new(from, config: @config)
          surface, kind = Molecules::DesignSource.scope(surface: surface, kind: kind, profile: profile, source: source.info)
          origin = prompt.nil? ? "default" : "explicit"
          if prompt.nil? && source.info&.fetch("type") == "session"
            prompt = File.read(File.join(source.info.fetch("root"), "brief.md"))
            origin = "session"
          end
          prompt ||= "#{intent.capitalize} the supplied interface, preserving its goals and functions." unless intent == "explore"
          Atoms::Contracts.text(prompt, "prompt")
          raise Error, "prompt_append must be a list" unless prompt_append.is_a?(Array)
          prompt_append.each { |text| Atoms::Contracts.text(text, "prompt-append") }
          brief_inputs = {"origin" => origin, "base" => prompt, "append" => prompt_append.dup}
          prompt = ([prompt] + prompt_append).join("\n\n")
          assumptions = Molecules::DesignContext.new.snapshot(surface: surface, kind: kind, context: profile, readonly: dry_run)
          language ||= @config.fetch("language")
          Atoms::Contracts.text(language, "language")
          resolved = Molecules::Preset.load(name: preset, surface: surface, config: @config, model: model,
            prompts: variant_prompts, prompt_files: variant_prompt_files, kind: kind, intent: intent)
          # Validate all declarations before creating a session or starting preparation.
          @executor.validate_model(resolved.fetch("preparation_model"))
          resolved.fetch("variants").each do |slot|
            @executor.validate_model(slot.fetch("model"), execution_preset: slot["execution_preset"])
          end
          begin
            fixture_bytes = fixtures && File.binread(fixtures)
          rescue SystemCallError => e
            raise Error, "Cannot read --fixtures #{fixtures}: #{e.message}"
          end
          Atoms::Contracts.object(JSON.parse(fixture_bytes), "fixtures") if fixture_bytes
          snapshot = load_context(resolved.fetch("input") + input)
          requirements = Molecules::SkillSources.new(@config).requirements(resolved) + source.requirements
          resolved["brief_inputs"] = brief_inputs
          resolved["requirements"] = requirements
          resolved["profile"] = assumptions.reject { |key, _| key == "document" }
          resolved["source"] = source.info
          resolved["surface"], resolved["kind"] = surface, kind
          if dry_run
            return {"status" => "planned", "resolved" => resolved, "requirements" => requirements, "brief" => prompt, "input_snapshot" => snapshot,
              "fixtures_sha256" => fixture_bytes && Digest::SHA256.hexdigest(fixture_bytes),
              "next" => "Run the same command without --dry-run"}
          end
          missing = requirements.select { |entry| entry["status"] == "missing" }
          raise Error, "Missing preset requirements: #{missing.map { |r| r['name'] }.join(', ')}" unless missing.empty?
          root = allocate_session
          source.snapshot(root)
          Molecules::SkillSources.new(@config).snapshot(root, resolved)
          metadata = {"intent" => intent, "source" => source.info, "surface" => surface, "kind" => kind, "title" => prompt.lines.find { |line| !line.strip.empty? }.strip[0, 120], "language" => language,
            "variants" => resolved.fetch("variants").map { |s| s.fetch("id") }}
          Molecules::Artifacts.json(File.join(root, "session.json"), metadata)
          Molecules::Artifacts.json(File.join(root, "resolved.json"), resolved)
          File.write(File.join(root, "brief.md"), prompt)
          File.write(File.join(root, "context.md"), snapshot)
          File.write(File.join(root, "design.md"), assumptions.fetch("document"))
          File.binwrite(File.join(root, "fixtures.json"), fixture_bytes) if fixture_bytes
          state = {"project_root" => Dir.pwd, "status" => "prepared", "preparation" => {"status" => "pending"},
            "supplied_fixtures" => !!fixture_bytes,
            "inputs" => %w[brief.md context.md design.md session.json resolved.json].to_h { |f| [f, Digest::SHA256.file(File.join(root, f)).hexdigest] },
            "workers" => metadata.fetch("variants").to_h { |id| [id, {"status" => "pending", "attempts" => []}] }}
          state["inputs"]["fixtures.json"] = Digest::SHA256.hexdigest(fixture_bytes) if fixture_bytes
          %w[source skills].each do |folder|
            directory = File.join(root, folder)
            next unless File.directory?(directory)
            Molecules::Artifacts.files(directory).each do |file|
              state["inputs"]["#{folder}/#{file}"] = Digest::SHA256.file(File.join(directory, file)).hexdigest
            end
          end
          Molecules::Artifacts.json(File.join(root, "run.json"), state)
          FileUtils.mkdir_p(File.join(root, "prompts"))
          File.write(File.join(root, "prompts/system.md"), Molecules::DesignPrompts::SYSTEM)
          File.write(File.join(root, "prompts/preparation.md"), Molecules::DesignPrompts.preparation(metadata, resolved, supplied: !!fixture_bytes))
          resolved.fetch("variants").each do |slot|
            File.write(File.join(root, "prompts/#{slot.fetch('id')}.md"), Molecules::DesignPrompts.variant(metadata, slot))
          end
          warn "Design session: #{root}"
          run = DesignRun.new(root, executor: @executor)
          run.resume
        rescue JSON::ParserError => e
          raise Error, "Invalid fixtures JSON: #{e.message}"
        ensure
          FileUtils.rm_rf(root) if root && !File.file?(File.join(root, "run.json"))
        end
        private
        def allocate_session
          base = File.expand_path(@config.fetch("run_root"))
          FileUtils.mkdir_p(base)
          100.times do
            root = File.join(base, Ace::B36ts.encode(Time.now, format: :ms))
            begin
              Dir.mkdir(root)
              return root
            rescue Errno::EEXIST
              sleep 0.002
            end
          end
          raise Error, "Could not allocate a unique Base36 session"
        end
        def load_context(inputs)
          inputs.map do |input|
            Atoms::Contracts.text(input, "context reference")
            bundle = Ace::Bundle.load_auto(input, compressor: "off", allow_commands: false, allowed_root: Dir.pwd)
            error = bundle.metadata[:error] || bundle.metadata["error"]
            raise Error, "Context #{input}: #{error}" if error
            raise Error, "Context #{input} is empty" if bundle.content.to_s.strip.empty?
            "# Context: #{input}\n\n#{bundle.content}"
          end.join("\n\n")
        end
      end
    end
  end
end

# frozen_string_literal: true
module Ace
  module Design
    module Molecules
      class Preset
        ID = /\A[a-z][a-z0-9_-]{0,31}\z/
        def self.integer(value, label)
          unless value.is_a?(Integer) || (value.is_a?(String) && /\A[+-]?\d+\z/.match?(value))
            raise Error, "#{label} must be an integer"
          end
          Integer(value)
        end
        def self.definition(name)
          if File.file?(name)
            data = YAML.safe_load_file(name)
            raise Error, "Preset file must be an object" unless data.is_a?(Hash)
            data
          else
            raise Error, "Invalid preset name" unless ID.match?(name)
            data = Ace::Support::Config.create(gem_path: Design.gem_root)
              .resolve_namespace("design", filename: "presets/#{name}").to_h
            raise Error, "Unknown preset: #{name}" if data.empty?
            data
          end
        end
        def self.compatibility!(data, intent, surface, kind)
          {"intents" => intent, "surfaces" => surface, "kinds" => kind}.each do |key, value|
            next unless data[key]
            allowed = {"intents" => %w[explore recreate reimagine], "surfaces" => %w[site app], "kinds" => %w[view component]}.fetch(key)
            unless data[key].is_a?(Array) && !data[key].empty? && (data[key] - allowed).empty?
              raise Error, "Preset #{key} must be a nonempty list drawn from #{allowed.join(', ')}"
            end
            raise Error, "Preset does not support #{key}: #{value}" unless data.fetch(key).include?(value)
          end
        end
        def self.list
          paths = Ace::Support::Config::Molecules::ConfigFinder.new(gem_path: Design.gem_root,
            file_patterns: ["design/presets/*.yml", "design/presets/*.yaml"]).find_all
          paths.map { |entry| File.basename(entry.path).sub(/\.ya?ml\z/, "") }
            .uniq.sort.map { |name| definition(name).merge("name" => name) }
        end
        def self.load(name:, surface:, config: Design.config, model: nil, prompts: [], prompt_files: [], kind: "view", intent: "explore")
          raise Error, "Invalid preset name" unless name.is_a?(String) && (ID.match?(name) || File.file?(name))
          Atoms::Contracts.surface(surface)
          Atoms::Contracts.kind(kind)
          data = definition(name)
          raise Error, "Unknown or empty design preset: #{name}" if data.empty?
          raise Error, "Unsupported intent: #{intent}" unless %w[explore recreate reimagine].include?(intent)
          compatibility!(data, intent, surface, kind)
          slots = data["variants"] || Array.new(intent == "recreate" ? 1 : 3) { |i| {"id" => (97 + i).chr} }
          unless slots.is_a?(Array) && !slots.empty? && slots.all? { |slot| slot.is_a?(Hash) }
            raise Error, "Preset variants must be a nonempty list of objects"
          end
          slots = slots.map do |slot|
            base = slot["preset"] ? definition(slot["preset"]) : data
            raise Error, "A variant must reference a single-process preset, not a comparison" if slot["preset"] && base.key?("variants")
            compatibility!(base, intent, surface, kind)
            JSON.parse(JSON.generate(base.reject { |key, _| %w[variants concurrency].include?(key) }.merge(slot)))
          end
          unless slots.is_a?(Array) && !slots.empty? && slots.all? { |s| s.is_a?(Hash) && ID.match?(s["id"].to_s) }
            raise Error, "Preset variants must be a nonempty list with safe lowercase IDs"
          end
          ids = slots.map { |s| s["id"] }
          raise Error, "Variant IDs must be unique" unless ids.uniq == ids
          extras = ids.to_h { |id| [id, []] }
          [[prompts, false], [prompt_files, true]].each do |entries, file|
            entries.each do |entry|
              id, value = entry.split("=", 2)
              raise Error, "Expected declared variant ID=VALUE: #{entry}" unless extras.key?(id) && value && !value.empty?
              begin
                extras[id] << (file ? File.read(value) : value)
              rescue SystemCallError => e
                raise Error, "Variant prompt file #{id}=#{value}: #{e.message}"
              end
            end
          end
          slots = slots.map do |slot|
            focus = slot["focus"] || Array(data["directions"])[ids.index(slot["id"])]
            focus = (kind == "component" && focus["component"]) || focus[surface] if focus.is_a?(Hash)
            resolved = slot.merge("focus" => focus.to_s,
              "model" => model || slot["model"] || data["model"] || config.fetch("model"),
              "role" => slot.fetch("role", "Design a distinct, useful #{surface} mockup."),
              "prompt" => ([slot["prompt"]] + extras.fetch(slot["id"])).compact.join("\n\n"))
            %w[model role prompt focus].each do |key|
              raise Error, "Variant #{slot['id']} #{key} must be text" unless resolved[key].is_a?(String)
            end
            Atoms::Contracts.text(resolved["model"], "variant model")
            if resolved.key?("execution_preset")
              Atoms::Contracts.text(resolved["execution_preset"], "execution preset")
              raise Error, "Use model@preset or execution_preset, not both" if resolved["model"].include?("@")
            end
            resolved.delete("directions")
            process = resolved.fetch("process", "ace")
            raise Error, "Unknown preset process: #{process}" unless %w[ace external].include?(process)
            if process == "external"
              skills = resolved["skills"]
              unless skills.is_a?(Array) && !skills.empty? && skills.all? { |skill| skill.is_a?(Hash) && skill["source"].is_a?(String) && skill["entry"].is_a?(String) && /\A[0-9a-f]{40}\z/.match?(skill["revision"].to_s) }
                raise Error, "External preset requires pinned skill sources, entries and full revisions"
              end
              raise Error, "External preset needs exactly one lead skill" unless skills.count { |skill| skill.fetch("role", "lead") == "lead" } == 1
            end
            types = resolved.fetch("artifact_types", ["html"])
            raise Error, "Invalid artifact_types" unless types.is_a?(Array) && !types.empty? && (types - %w[html image url]).empty?
            resolved
          end
          concurrency = integer(data.fetch("concurrency", 3), "concurrency")
          timeout = integer(data.fetch("timeout", config.fetch("agent_timeout")), "agent timeout")
          raise Error, "concurrency must be positive" unless concurrency.positive?
          raise Error, "agent timeout must be 1..3600 seconds" unless (1..3600).cover?(timeout)
          {"name" => name, "variants" => slots, "concurrency" => [concurrency, slots.size].min,
           "timeout" => timeout, "preparation_model" => model || data["preparation_model"] || data["model"] || config.fetch("model"),
           "input" => Array(config["input"]) + Array(data["input"]), "intent" => intent,
           "model_override" => model, "description" => data["description"]}
        rescue SystemCallError, ArgumentError, TypeError => e
          raise Error, "Invalid design preset: #{e.message}"
        end
      end
    end
  end
end

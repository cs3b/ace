# frozen_string_literal: true
module Ace
  module Design
    module CLI
      module Commands
        class Explore < Ace::Support::Cli::Command
          desc "Explore new directions from a brief"
          option :surface, type: :string, desc: "site or app; inferred from profile or session source"
          option :kind, type: :string, desc: "view (default) or component"
          option :profile, type: :string, desc: "Project design profile"
          option :from, type: :string, desc: "Source image, HTTP(S) URL or session:TOKEN/VARIANT; recreate/reimagine only"
          option :prompt, type: :string, desc: "Base brief (required for explore); replaces inherited session brief"
          option :prompt_append, type: :string, desc: "Repeatable guidance appended to the base brief in order"
          option :preset, type: :string, default: "fast", desc: "Preset name or YAML file"
          option :input, type: :string, desc: "Repeatable reference file, protocol or bundle preset"
          option :fixtures, type: :string, desc: "Shared JSON object; preserve exact bytes"
          option :model, type: :string, desc: "Override preparation and ALL variant models"
          option :language, type: :string, desc: "One exploration language"
          option :variant_prompt, type: :string, desc: "Repeatable ID=additional guidance"
          option :variant_prompt_file, type: :string, desc: "Repeatable ID=prompt file"
          option :dry_run, type: :boolean, default: false, desc: "Resolve without models, source fetching or session creation"
          option :json, type: :boolean, default: false, desc: "Machine-readable result; progress stays on stderr"
          def call(input: nil, prompt_append: nil, variant_prompt: nil, variant_prompt_file: nil, json: false, **options)
            intent = self.class.name.split("::").last.downcase
            result = Organisms::Generator.new.generate(intent: intent, input: CLI.entries(input),
              prompt_append: prompt_append.nil? ? [] : prompt_append.split("\x1f", -1),
              variant_prompts: CLI.entries(variant_prompt), variant_prompt_files: CLI.entries(variant_prompt_file),
              **options.except(:args))
            CLI.output(result, json: json)
            %w[planned succeeded].include?(result["status"]) ? 0 : 2
          end
        end
        class Recreate < Explore
          desc "Faithfully recreate an image, URL or previous variant"
        end
        class Reimagine < Explore
          desc "Keep source goals and functions, replace its visual direction"
        end
      end
    end
  end
end

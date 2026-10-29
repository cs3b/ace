# frozen_string_literal: true

module Ace
  module Overseer
    module Atoms
      # Pure validation and normalization of the `start` contract
      # (task 8xs.t.pu0.1): the `.ace/overseer/config.yml` cascade must
      # carry an EXPLICIT start section — `scope: project|lab`, a
      # `profile` reference into the same document's `profiles` map and
      # an `instructions` source (wfi:// or an absolute file path).
      # Nothing is guessed: a missing or ambiguous section is an error
      # BEFORE any session is created, and no interim default model is
      # applied anywhere. Pure — no IO, value-free messages.
      class StartContract
        SCOPES = %w[project lab].freeze
        SECTION_KEYS = %w[scope profile instructions].freeze
        PROFILE_KEYS = %w[harness model thinking].freeze
        INSTRUCTION_PROTOCOLS = %w[wfi:// prompt:// tmpl://].freeze

        # @param config [Hash] resolved overseer config (cascade output)
        # @return [Hash] normalized start plan fragment:
        #   {scope:, profile_name:, profile: {harness:, model:,
        #   thinking:}, instructions:}
        # @raise [Ace::Overseer::Error] missing/ambiguous/invalid start
        #   configuration
        def self.normalize(config)
          start = config["start"]
          unless start.is_a?(Hash)
            raise Ace::Overseer::Error,
              "ace-overseer start requires an explicit 'start' section in " \
              ".ace/overseer/config.yml (scope, profile, instructions); " \
              "none is configured for this directory"
          end

          unknown = start.keys - SECTION_KEYS
          unless unknown.empty?
            raise Ace::Overseer::Error,
              "start section has unknown key '#{unknown.sort.first}' " \
              "(allowed: #{SECTION_KEYS.join(', ')})"
          end

          scope = required(start, "scope")
          unless SCOPES.include?(scope)
            raise Ace::Overseer::Error,
              "start scope must be one of: #{SCOPES.join(', ')} (got '#{scope}')"
          end
          if scope == "lab"
            raise Ace::Overseer::Error,
              "start scope 'lab' is not implemented yet (planned with the " \
                "lab-level start, step 8xs.t.pu0.a); this slice starts a " \
                "single project overseer"
          end

          profile_name = required(start, "profile")
          profile = profile_for(config, profile_name)

          instructions = required(start, "instructions")
          unless INSTRUCTION_PROTOCOLS.any? { |prefix| instructions.start_with?(prefix) } ||
            instructions.start_with?("/")
            raise Ace::Overseer::Error,
              "start instructions must be a wfi:// (or prompt://, tmpl://) " \
                "source or an absolute file path"
          end

          {"scope" => scope, "profile_name" => profile_name,
           "profile" => profile, "instructions" => instructions}
        end

        # The pane/tab label that OWNS this project's overseer session:
        # derived from the project root so every start from the same
        # repository (subdirectory, symlink, worktree) converges on the
        # same owner identity.
        def self.session_label(project_root)
          "overseer-#{File.basename(project_root)}"
        end

        def self.profile_for(config, profile_name)
          profiles = config["profiles"]
          unless profiles.is_a?(Hash) && profiles[profile_name].is_a?(Hash)
            raise Ace::Overseer::Error,
              "start profile '#{profile_name}' is not configured; declare it " \
                "under 'profiles' in .ace/overseer/config.yml"
          end

          raw = profiles[profile_name]
          unknown = raw.keys - PROFILE_KEYS
          unless unknown.empty?
            raise Ace::Overseer::Error,
              "profile '#{profile_name}' has unknown key '#{unknown.sort.first}' " \
                "(allowed: #{PROFILE_KEYS.join(', ')})"
          end

          harness = required_value(raw, "harness", "profile '#{profile_name}'")
          model = required_value(raw, "model", "profile '#{profile_name}'")
          thinking = raw["thinking"]

          {"harness" => harness, "model" => model, "thinking" => thinking}
        end

        def self.required(start, key)
          value = start[key]
          unless value.is_a?(String) && !value.strip.empty?
            raise Ace::Overseer::Error,
              "start section key '#{key}' is required and must be a non-empty string"
          end

          value.strip
        end

        def self.required_value(raw, key, owner)
          value = raw[key]
          unless value.is_a?(String) && !value.strip.empty?
            raise Ace::Overseer::Error, "#{owner} key '#{key}' is required"
          end

          value.strip
        end
      end
    end
  end
end

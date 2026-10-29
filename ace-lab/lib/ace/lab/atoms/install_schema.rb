# frozen_string_literal: true

require "rubygems/version"

module Ace
  module Lab
    module Atoms
      # Pure validation and normalization of the trusted install manifest
      # (v1). The manifest is a deployment document read from a fixed
      # root-owned path — never from the caller-writable cascade — so this
      # atom only checks structure; it performs no IO and raises value-free
      # messages naming the offending section (the caller cannot use schema
      # errors to echo untrusted content back into diagnostics).
      class InstallSchema
        SCHEMA_VERSION = 1
        TOP_LEVEL_KEYS =
          %w[schema_version machine accounts directories keys roles projects grants
             adapters tools gemset].freeze
        ENTRY_KEYS = {
          "accounts" => %w[username role create home],
          "directories" => %w[path owner mode],
          "keys" => %w[account type path],
          "roles" => %w[id account instructions],
          "projects" => %w[id path remote label],
          "adapters" => %w[id kind command config]
        }.freeze
        USERNAME_PATTERN = /\A[a-z_][a-z0-9_-]{0,31}\z/
        ROLE_ID_PATTERN = /\A[a-z][a-z0-9_-]{0,31}\z/
        INSTRUCTION_PROTOCOLS = %w[wfi:// prompt:// tmpl://].freeze
        ADAPTER_KINDS = %w[communication hitl].freeze
        DEFAULT_MODE = "0755"
        DEFAULT_KEY_TYPE = "ed25519"
        KEY_TYPES = [DEFAULT_KEY_TYPE].freeze
        GEMSET_KEYS = %w[gem_home gems extensions].freeze
        GEM_KEYS = %w[name version].freeze
        GEM_NAME_PATTERN = /\A[A-Za-z0-9._-]+\z/
        EXTENSION_KEYS = %w[gem path account].freeze

        class << self
          # @param document [Object] parsed YAML document
          # @param platform [String, nil] "darwin" / "linux" (home defaults);
          #   nil resolves through the Ace::Lab.host_platform seam
          # @return [Hash] normalized manifest with defaults applied
          # @raise [Ace::Lab::InvalidConfigurationError]
          def normalize(document, platform: nil)
            unless document.is_a?(Hash)
              raise_invalid "manifest must be a mapping"
            end

            version = document["schema_version"]
            unless version == SCHEMA_VERSION
              raise_invalid "schema_version must be #{SCHEMA_VERSION}"
            end

            unknown = document.keys - TOP_LEVEL_KEYS
            unless unknown.empty?
              raise_invalid "unknown top-level key '#{unknown.sort.first}'"
            end

            machine = document["machine"]
            unless machine.is_a?(String) && !machine.empty? && machine !~ /\s/
              raise_invalid "machine must be a non-empty string without whitespace"
            end

            os = platform || Ace::Lab.host_platform
            accounts = normalize_accounts(document["accounts"], os)
            usernames = accounts.map { |account| account["username"] }
            projects = normalize_projects(document["projects"])

            {
              "schema_version" => SCHEMA_VERSION,
              "machine" => machine,
              "accounts" => accounts,
              "directories" => normalize_directories(document["directories"], usernames),
              "keys" => normalize_keys(document["keys"], accounts),
              "roles" => normalize_roles(document["roles"], usernames),
              "projects" => projects,
              "grants" => normalize_grants(document["grants"], projects.map { |p| p["id"] }),
              "adapters" => normalize_adapters(document["adapters"]),
              "tools" => normalize_tools(document["tools"]),
              "gemset" => normalize_gemset(document["gemset"], accounts.map { |a| a["username"] })
            }
          end

          private

          def raise_invalid(reason)
            raise Ace::Lab::InvalidConfigurationError,
              "invalid lab install manifest: #{reason}"
          end

          def raise_invalid_entry(section, reason)
            raise_invalid "#{section} entry #{reason}"
          end

          def section(raw, name)
            value = raw.nil? ? [] : raw
            unless value.is_a?(Array)
              raise_invalid "#{name} must be a list"
            end
            value.each_with_index do |entry, index|
              unless entry.is_a?(Hash)
                raise_invalid_entry(name, "##{index} must be a mapping")
              end
              next if ENTRY_KEYS[name].nil?

              unknown = entry.keys - ENTRY_KEYS[name]
              unless unknown.empty?
                raise_invalid_entry(name, "##{index} has unknown key '#{unknown.sort.first}'")
              end
            end
            value
          end

          def normalize_accounts(raw, platform)
            section(raw, "accounts").map do |entry|
              username = required_string(entry, "accounts", "username")
              unless username =~ USERNAME_PATTERN
                raise_invalid_entry("accounts", "username format is invalid")
              end

              role = required_string(entry, "accounts", "role")

              create = entry.key?("create") ? entry["create"] : false
              unless [true, false].include?(create)
                raise_invalid_entry("accounts", "create must be a boolean")
              end

              home = entry["home"]
              if home.nil?
                home = default_home(username, platform)
              elsif !home.is_a?(String) || !absolute_path?(home)
                raise_invalid_entry("accounts", "home must be an absolute path")
              end

              {"username" => username, "role" => role, "create" => create, "home" => home}
            end.tap do |accounts|
              duplicates_of(accounts.map { |a| a["username"] }) do |_username|
                raise_invalid_entry("accounts", "username is declared more than once")
              end
            end
          end

          def normalize_directories(raw, usernames)
            section(raw, "directories").map do |entry|
              path = required_string(entry, "directories", "path")
              unless absolute_path?(path)
                raise_invalid_entry("directories", "path must be an absolute path")
              end

              owner = entry["owner"]
              if !owner.nil?
                unless owner.is_a?(String) && usernames.include?(owner)
                  raise_invalid_entry("directories", "owner must reference a declared account")
                end
              end

              {"path" => path, "owner" => owner, "mode" => normalize_mode(entry["mode"])}
            end
          end

          def normalize_keys(raw, accounts)
            homes = accounts.to_h { |account| [account["username"], account["home"]] }
            section(raw, "keys").map do |entry|
              account = required_string(entry, "keys", "account")
              home = homes[account]
              unless home
                raise_invalid_entry("keys", "account must reference a declared account")
              end

              type = entry.key?("type") ? entry["type"] : DEFAULT_KEY_TYPE
              unless KEY_TYPES.include?(type)
                raise_invalid_entry("keys", "type must be one of: #{KEY_TYPES.join(', ')}")
              end

              path = entry["path"]
              if path.nil?
                path = File.join(home, ".ssh", "id_#{type}")
              elsif !path.is_a?(String) || !absolute_path?(path)
                raise_invalid_entry("keys", "path must be an absolute path")
              end

              {"account" => account, "type" => type, "path" => path}
            end.tap do |keys|
              duplicates_of(keys.map { |key| key["path"] }) do |_path|
                raise_invalid_entry("keys", "path is declared more than once")
              end
            end
          end

          def normalize_roles(raw, usernames)
            section(raw, "roles").map do |entry|
              id = required_string(entry, "roles", "id")
              unless id =~ ROLE_ID_PATTERN
                raise_invalid_entry("roles", "id format is invalid")
              end

              account = required_string(entry, "roles", "account")
              unless usernames.include?(account)
                raise_invalid_entry("roles", "account must reference a declared account")
              end

              instructions = required_string(entry, "roles", "instructions")
              unless instruction_source?(instructions)
                raise_invalid_entry("roles",
                  "instructions must use a wfi://, prompt:// or tmpl:// prefix or be an absolute file path")
              end

              {"id" => id, "account" => account, "instructions" => instructions}
            end.tap do |roles|
              duplicates_of(roles.map { |role| role["id"] }) do |_id|
                raise_invalid_entry("roles", "id is declared more than once")
              end
            end
          end

          def normalize_projects(raw)
            section(raw, "projects").map do |entry|
              id = required_string(entry, "projects", "id")
              unless id =~ ROLE_ID_PATTERN
                raise_invalid_entry("projects", "id format is invalid")
              end

              path = required_string(entry, "projects", "path")
              unless absolute_path?(path)
                raise_invalid_entry("projects", "path must be an absolute path")
              end

              remote = optional_string(entry, "projects", "remote")
              label = optional_string(entry, "projects", "label")

              {"id" => id, "path" => path, "remote" => remote, "label" => label}
            end.tap do |projects|
              duplicates_of(projects.map { |project| project["id"] }) do |_id|
                raise_invalid_entry("projects", "id is declared more than once")
              end
              duplicates_of(projects.map { |project| project["path"] }) do |_path|
                raise_invalid_entry("projects", "path is declared more than once")
              end
            end
          end

          def normalize_grants(raw, project_ids)
            grants = raw.nil? ? {} : raw
            unless grants.is_a?(Hash)
              raise_invalid "grants must be a mapping of principal to project ids"
            end

            # Reject duplicates after strip, like the other duplicate
            # checks (review r1): "admin" and " admin " would otherwise
            # silently last-wins.
            duplicates_of(grants.keys.filter_map { |key| key.strip if key.is_a?(String) }) do |_principal|
              raise_invalid "grants principal name is declared more than once"
            end

            grants.to_h do |principal, projects|
              unless principal.is_a?(String) && !principal.strip.empty?
                raise_invalid "grants principal name must be a non-empty string"
              end
              unless projects.is_a?(Array) && !projects.empty? &&
                projects.all? { |project| project.is_a?(String) && !project.strip.empty? }
                raise_invalid "grants for principal '#{principal.strip}' must be a non-empty " \
                  "list of project ids"
              end
              duplicates_of(projects.map(&:strip)) do |_project|
                raise_invalid "grants for principal '#{principal.strip}' list a project more than once"
              end
              unknown = projects.map(&:strip) - project_ids
              unless unknown.empty?
                raise_invalid "grants for principal '#{principal.strip}' reference project " \
                  "'#{unknown.sort.first}' which the manifest does not declare"
              end

              [principal.strip, projects.map(&:strip).uniq]
            end
          end

          # Selected communication/HITL adapters (task 8xg.t.sbz.7.2):
          # each declares an id, a kind, an optional local command that
          # provides the adapter (probed for availability by verify) and
          # an optional free-form configuration mapping. Real network
          # traffic stays out of scope (L9) — this is the declaration
          # surface install validates and verify probes.
          def normalize_adapters(raw)
            section(raw, "adapters").map do |entry|
              id = required_string(entry, "adapters", "id")
              unless id =~ ROLE_ID_PATTERN
                raise_invalid_entry("adapters", "id format is invalid")
              end

              kind = required_string(entry, "adapters", "kind")
              unless ADAPTER_KINDS.include?(kind)
                raise_invalid_entry("adapters",
                  "kind must be one of: #{ADAPTER_KINDS.join(', ')}")
              end

              command = optional_string(entry, "adapters", "command")

              config = entry["config"].nil? ? {} : entry["config"]
              unless config.is_a?(Hash)
                raise_invalid_entry("adapters", "config must be a mapping when present")
              end

              {"id" => id, "kind" => kind, "command" => command, "config" => config}
            end.tap do |adapters|
              duplicates_of(adapters.map { |adapter| adapter["id"] }) do |_id|
                raise_invalid_entry("adapters", "id is declared more than once")
              end
            end
          end

          # Required tools (task 8xg.t.sbz.7.4): names the lab needs on
          # PATH for the target accounts; verify probes each one's
          # presence (no execution, no network).
          def normalize_tools(raw)
            tools = raw.nil? ? [] : raw
            unless tools.is_a?(Array) && tools.all? { |tool| tool.is_a?(String) && !tool.strip.empty? }
              raise_invalid "tools must be a list of non-empty strings"
            end

            duplicates_of(tools.map(&:strip)) do |_tool|
              raise_invalid "tools list a tool more than once"
            end
            tools.map(&:strip).uniq
          end

          # Target lab runtime, required gem set and harness extension
          # projections (gad.2 gap #1, owner spec 8xg.t.sbz.7; task
          # 8xs.t.pu0.0): a sibling of `tools` declaring WHERE the
          # lab's gems must live (`gem_home`, converged as GEM_HOME/
          # GEM_PATH), WHICH gems at WHICH exact versions, and WHICH
          # installed gems' handbook/extensions trees are projected
          # into WHICH target extension directories. Absent = no
          # runtime declared, behavior unchanged. Names must be real
          # gem names; versions must parse as exact Gem versions (the
          # same parser the runtime uses) — ranges and bare names are
          # rejected so convergence is always exact-version. An
          # extension entry must reference a declared gem and a
          # declared account (the executor whose harness loads the
          # projection) and carries an absolute target path.
          def normalize_gemset(raw, usernames)
            return {"gem_home" => nil, "gems" => [], "extensions" => []} if raw.nil?
            unless raw.is_a?(Hash)
              raise_invalid "gemset must be a mapping"
            end

            unknown = raw.keys - GEMSET_KEYS
            unless unknown.empty?
              raise_invalid "gemset has unknown key '#{unknown.sort.first}'"
            end

            gem_home = raw["gem_home"]
            unless gem_home.is_a?(String) && !gem_home.strip.empty? && absolute_path?(gem_home.strip)
              raise_invalid "gemset gem_home is required and must be an absolute path"
            end

            {"gem_home" => gem_home.strip, "gems" => normalize_gems(raw["gems"]),
             "extensions" => normalize_extensions(raw["extensions"], raw["gems"], usernames)}
          end

          # Harness extension projections: each entry names a DECLARED
          # gem (the projection source — the gem's handbook/extensions
          # tree at its exact declared version), an absolute target
          # path (the harness extension directory) and the declared
          # account whose executor loads it. The manifest stays the
          # single owner of the declaration; the projection itself is
          # re-derived from the installed gem on every run.
          def normalize_extensions(raw, gems, usernames)
            entries = raw.nil? ? [] : raw
            unless entries.is_a?(Array)
              raise_invalid "gemset extensions must be a list"
            end
            entries.each_with_index do |entry, index|
              unless entry.is_a?(Hash)
                raise_invalid "gemset extensions entry ##{index} must be a mapping"
              end
              unknown = entry.keys - EXTENSION_KEYS
              unless unknown.empty?
                raise_invalid "gemset extensions entry ##{index} has unknown key '#{unknown.sort.first}'"
              end
            end

            declared = (gems || []).filter_map do |gem|
              gem.is_a?(Hash) && gem["name"].is_a?(String) ? gem["name"].strip : nil
            end
            entries.map do |entry|
              gem = required_string(entry, "gemset extensions", "gem")
              unless declared.include?(gem)
                raise_invalid_entry("gemset extensions",
                  "gem '#{gem}' must be declared in gemset gems before it can project an extension")
              end

              path = required_string(entry, "gemset extensions", "path")
              unless absolute_path?(path)
                raise_invalid_entry("gemset extensions", "path must be an absolute path")
              end

              account = required_string(entry, "gemset extensions", "account")
              unless usernames.include?(account)
                raise_invalid_entry("gemset extensions",
                  "account must reference a declared account")
              end

              {"gem" => gem, "path" => path.strip, "account" => account}
            end
          end

          def normalize_gems(raw)
            gems = raw.nil? ? [] : raw
            unless gems.is_a?(Array)
              raise_invalid "gemset gems must be a list"
            end
            gems.each_with_index do |entry, index|
              unless entry.is_a?(Hash)
                raise_invalid "gemset gems entry ##{index} must be a mapping"
              end
              unknown = entry.keys - GEM_KEYS
              unless unknown.empty?
                raise_invalid "gemset gems entry ##{index} has unknown key '#{unknown.sort.first}'"
              end
            end

            gems.map do |entry|
              name = entry["name"]
              unless name.is_a?(String) && name.strip =~ GEM_NAME_PATTERN
                raise_invalid_entry("gemset gems", "name is required and must be a gem name")
              end
              version = entry["version"]
              unless version.is_a?(String) && !version.strip.empty?
                raise_invalid_entry("gemset gems", "version is required and must be an exact version")
              end
              begin
                Gem::Version.new(version.strip)
              rescue ArgumentError
                raise_invalid_entry("gemset gems", "version must be an exact gem version")
              end

              {"name" => name.strip, "version" => version.strip}
            end.tap do |gems|
              duplicates_of(gems.map { |gem| gem["name"] }) do |_name|
                raise_invalid_entry("gemset gems", "name is declared more than once")
              end
            end
          end

          def optional_string(entry, section_name, field)
            value = entry[field]
            if !value.nil? && (!value.is_a?(String) || value.strip.empty?)
              raise_invalid_entry(section_name, "#{field} must be a non-empty string when present")
            end
            value.nil? ? nil : value.strip
          end

          def required_string(entry, section_name, field)
            value = entry[field]
            unless value.is_a?(String) && !value.strip.empty?
              raise_invalid_entry(section_name, "#{field} is required and must be a non-empty string")
            end
            value
          end

          def normalize_mode(raw)
            mode = raw.nil? ? DEFAULT_MODE : raw
            unless mode.is_a?(String) && mode.match?(/\A[0-7]{3,4}\z/)
              raise_invalid_entry("directories", "mode must be an octal string like \"0750\"")
            end

            format("%04o", mode.to_i(8))
          end

          def absolute_path?(path)
            path.start_with?("/")
          end

          def instruction_source?(instructions)
            INSTRUCTION_PROTOCOLS.any? { |protocol| instructions.start_with?(protocol) } ||
              absolute_path?(instructions)
          end

          def default_home(username, platform)
            prefix = platform == "darwin" ? "/Users" : "/home"
            File.join(prefix, username)
          end

          def duplicates_of(values)
            seen = {}
            values.each do |value|
              if seen[value]
                yield value
              else
                seen[value] = true
              end
            end
          end
        end
      end
    end
  end
end

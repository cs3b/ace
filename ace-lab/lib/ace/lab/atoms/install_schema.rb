# frozen_string_literal: true

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
        USERNAME_PATTERN = /\A[a-z_][a-z0-9_-]{0,31}\z/
        ROLE_ID_PATTERN = /\A[a-z][a-z0-9_-]{0,31}\z/
        INSTRUCTION_PROTOCOLS = %w[wfi:// prompt:// tmpl://].freeze
        DEFAULT_MODE = "0755"
        DEFAULT_KEY_TYPE = "ed25519"
        KEY_TYPES = [DEFAULT_KEY_TYPE].freeze

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

            machine = document["machine"]
            unless machine.is_a?(String) && !machine.empty? && machine !~ /\s/
              raise_invalid "machine must be a non-empty string without whitespace"
            end

            os = platform || Ace::Lab.host_platform
            accounts = normalize_accounts(document["accounts"], os)
            usernames = accounts.map { |account| account["username"] }

            {
              "schema_version" => SCHEMA_VERSION,
              "machine" => machine,
              "accounts" => accounts,
              "directories" => normalize_directories(document["directories"], usernames),
              "keys" => normalize_keys(document["keys"], accounts),
              "roles" => normalize_roles(document["roles"], usernames)
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

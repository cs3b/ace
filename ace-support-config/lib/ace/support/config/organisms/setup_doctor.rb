# frozen_string_literal: true

require "json"
require "open3"
require "rubygems"
require "time"

module Ace
  module Support
    module Config
      module Organisms
        class SetupDoctor
          PROVIDER_GEM = "ace-llm-providers-cli"
          PASS = "pass"
          WARN = "warn"
          BLOCKER = "blocker"
          SKIP = "skip"

          def run(json: false, no_probe: false, io: $stdout)
            checks = []

            checks << check_artifact_hygiene

            package_check = check_provider_package
            checks << package_check

            discovery_check = check_provider_discovery
            checks << discovery_check

            provider_context = load_provider_context if package_check[:status] != BLOCKER

            checks << check_alias_readiness(provider_context)
            checks << check_probe_readiness(provider_context, no_probe: no_probe)

            output_result(checks, json: json, io: io)
            blocking?(checks) ? 1 : 0
          end

          private

          def check_artifact_hygiene
            root = project_root
            gitignore_path = File.join(root, ".gitignore")
            unless File.exist?(gitignore_path)
              return check(
                id: "artifact-hygiene",
                status: BLOCKER,
                message: ".gitignore is missing at project root",
                next_action: "Create #{gitignore_path} and add .ace-local/."
              )
            end

            content = File.read(gitignore_path)
            if gitignore_entry_present?(content, ".ace-local/")
              check(id: "artifact-hygiene", status: PASS, message: ".ace-local/ is ignored")
            else
              check(
                id: "artifact-hygiene",
                status: BLOCKER,
                message: ".ace-local/ is not ignored",
                next_action: "Add .ace-local/ to #{gitignore_path}."
              )
            end
          end

          def check_provider_package
            installed = Gem::Specification.find_all_by_name(PROVIDER_GEM).any?
            return check(id: "provider-package", status: PASS, message: "CLI provider package #{PROVIDER_GEM} is available") if installed

            check(
              id: "provider-package",
              status: BLOCKER,
              message: "CLI provider package missing: #{PROVIDER_GEM}",
              next_action: "Install #{PROVIDER_GEM} and run bundle install."
            )
          rescue => e
            check(
              id: "provider-package",
              status: WARN,
              message: "Unable to verify provider package availability: #{e.message}",
              next_action: "Verify #{PROVIDER_GEM} is installed."
            )
          end

          def check_provider_discovery
            _out, err, status = Open3.capture3("ace-llm", "--list-providers")
            return check(id: "provider-discovery", status: PASS, message: "Provider discovery completed") if status.success?

            check(
              id: "provider-discovery",
              status: BLOCKER,
              message: "Provider discovery failed",
              next_action: discovery_next_action(err)
            )
          rescue Errno::ENOENT
            check(
              id: "provider-discovery",
              status: BLOCKER,
              message: "ace-llm command is unavailable",
              next_action: "Install ace-llm and #{PROVIDER_GEM}, then rerun ace-config doctor."
            )
          end

          def check_alias_readiness(provider_context)
            unless provider_context
              return check(
                id: "alias-readiness",
                status: WARN,
                message: "Alias readiness check skipped: provider context unavailable",
                next_action: "Ensure ace-llm is installed and provider discovery succeeds."
              )
            end

            stale = find_stale_aliases(provider_context)
            if stale.empty?
              return check(
                id: "alias-readiness",
                status: PASS,
                message: "Configured model aliases resolve"
              )
            end

            detail = stale.map { |item| "#{item[:provider]}:#{item[:alias]} -> #{item[:resolved]}" }.join(", ")
            check(
              id: "alias-readiness",
              status: BLOCKER,
              message: "Unsupported alias mappings detected: #{detail}",
              next_action: "Update aliases to declared provider models."
            )
          rescue => e
            check(
              id: "alias-readiness",
              status: WARN,
              message: "Alias readiness check failed: #{e.message}",
              next_action: "Review llm/providers alias configuration."
            )
          end

          def check_probe_readiness(provider_context, no_probe:)
            if no_probe
              return check(
                id: "probe-readiness",
                status: SKIP,
                message: "Live provider probes disabled by --no-probe"
              )
            end
            unless provider_context
              return check(
                id: "probe-readiness",
                status: WARN,
                message: "Probe readiness skipped: provider context unavailable",
                next_action: "Verify provider discovery first."
              )
            end

            providers = provider_context[:providers].select { |provider| provider[:available] }
            if providers.empty?
              return check(
                id: "probe-readiness",
                status: WARN,
                message: "No active providers available for probes",
                next_action: "Enable at least one provider and rerun ace-llm --list-providers."
              )
            end

            outcomes = providers.map { |provider| run_probe(provider) }
            return check(id: "probe-readiness", status: PASS, message: "Tiny provider probes completed") if outcomes.any? { |o| o[:status] == PASS }

            next_actions = outcomes.filter_map { |o| o[:next_action] }.uniq
            check(
              id: "probe-readiness",
              status: WARN,
              message: "Some providers require credentials or local account access",
              next_action: next_actions.first || "Authenticate at least one provider and rerun ace-config doctor."
            )
          end

          def run_probe(provider)
            if provider[:api_key_required] && !provider[:api_key_present]
              return {status: WARN, next_action: "Configure credentials for provider '#{provider[:name]}'."}
            end

            model = Array(provider[:models]).first
            return {status: WARN, next_action: "No model listed for provider '#{provider[:name]}'."} if model.nil? || model.empty?

            _out, err, status = Open3.capture3(
              "ace-llm",
              "#{provider[:name]}:#{model}",
              "ready?",
              "--max-tokens",
              "4",
              "--timeout",
              "15",
              "--quiet"
            )
            return {status: PASS} if status.success?

            if auth_related_error?(err)
              return {
                status: WARN,
                next_action: "Authenticate provider '#{provider[:name]}' and rerun."
              }
            end

            {status: WARN, next_action: "Probe failed for provider '#{provider[:name]}'. Verify setup and connectivity."}
          rescue
            {status: WARN, next_action: "Probe failed for provider '#{provider[:name]}'. Verify setup and connectivity."}
          end

          def load_provider_context
            require "ace/llm"
            require "ace/llm/molecules/client_registry"

            registry = Ace::LLM::Molecules::ClientRegistry.new
            {
              registry: registry,
              providers: registry.list_providers_with_status,
              aliases: registry.available_aliases
            }
          rescue LoadError, StandardError
            nil
          end

          def find_stale_aliases(provider_context)
            providers = provider_context[:providers]
            aliases = provider_context[:aliases] || {}
            provider_models = providers.to_h do |provider|
              [provider[:name].to_s, Array(provider[:models]).map(&:to_s)]
            end

            stale = []

            model_aliases = aliases[:model] || aliases["model"] || {}
            model_aliases.each do |provider_name, mapping|
              (mapping || {}).each do |alias_name, model_name|
                next if valid_provider_model_target?(provider_models, provider_name, model_name)

                stale << {provider: provider_name.to_s, alias: alias_name.to_s, resolved: model_name.to_s}
              end
            end

            global_aliases = aliases[:global] || aliases["global"] || {}
            registry = provider_context[:registry]
            global_aliases.each do |alias_name, target|
              provider_name, model_name = parse_provider_model_target(resolve_alias_target(registry, target))
              next unless provider_name && model_name
              next if valid_provider_model_target?(provider_models, provider_name, model_name)

              stale << {provider: provider_name, alias: alias_name.to_s, resolved: model_name}
            end

            stale
          end

          def output_result(checks, json:, io:)
            summary = build_summary(checks)
            if json
              io.puts JSON.pretty_generate(summary)
              return
            end

            io.puts "ACE setup doctor"
            checks.each do |check_row|
              io.puts "#{check_row[:status].upcase} #{check_row[:message]}"
              io.puts "  Next: #{check_row[:next_action]}" if check_row[:next_action]
            end
          end

          def build_summary(checks)
            {
              generated_at: Time.now.utc.iso8601,
              blocker_count: checks.count { |check_row| check_row[:status] == BLOCKER },
              warning_count: checks.count { |check_row| check_row[:status] == WARN },
              checks: checks
            }
          end

          def blocking?(checks)
            checks.any? { |check_row| check_row[:status] == BLOCKER }
          end

          def check(id:, status:, message:, next_action: nil)
            {id: id, status: status, message: message, next_action: next_action}
          end

          def discovery_next_action(stderr_output)
            text = stderr_output.to_s
            if text.include?(PROVIDER_GEM)
              "Install #{PROVIDER_GEM} and rerun ace-llm --list-providers."
            else
              "Run ace-llm --list-providers to inspect provider setup, then rerun ace-config doctor."
            end
          end

          def auth_related_error?(text)
            value = text.to_s.downcase
            value.include?("credential") ||
              value.include?("api key") ||
              value.include?("auth") ||
              value.include?("login")
          end

          def project_root
            Ace::Support::Config.find_project_root(start_path: Dir.pwd) || Dir.pwd
          end

          def gitignore_entry_present?(content, entry)
            target = canonical_ignore_token(entry)
            content.each_line.any? do |line|
              normalized = canonical_ignore_token(line)
              next false if normalized.nil?

              normalized == target || normalized.start_with?("#{target}/")
            end
          end

          def valid_provider_model_target?(provider_models, provider_name, model_name)
            expected = provider_models[provider_name.to_s] || []
            !expected.empty? && expected.include?(model_name.to_s)
          end

          def resolve_alias_target(registry, target)
            value = target.to_s
            return value unless registry&.respond_to?(:resolve_alias)

            registry.resolve_alias(value).to_s
          rescue StandardError
            value
          end

          def parse_provider_model_target(value)
            parts = value.to_s.split(":", 2)
            return [nil, nil] if parts.length != 2

            provider, model = parts
            return [nil, nil] if provider.to_s.empty? || model.to_s.empty?

            [provider.to_s, model.to_s]
          end

          def canonical_ignore_token(value)
            token = value.to_s.strip
            return nil if token.empty? || token.start_with?("#") || token.start_with?("!")

            token = token.delete_prefix("/")
            token = token.delete_suffix("/")
            token
          end
        end
      end
    end
  end
end

# frozen_string_literal: true

require "date"

module Ace
  module Support
    module Models
      module Organisms
        # Orchestrates the provider config synchronization workflow
        # Coordinates reading configs, generating diffs, applying changes, and committing
        class ProviderSyncOrchestrator
          PROVIDER_SYNC_CACHE_MAX_AGE = 86_400 * 7 # 7 days

          attr_reader :diff_generator, :output

          # Initialize orchestrator
          # @param cache_manager [Molecules::CacheManager, nil] Cache manager
          # @param output [IO] Output stream for messages
          def initialize(cache_manager: nil, output: $stdout)
            @cache_manager = cache_manager || Molecules::CacheManager.new
            @diff_generator = Molecules::ProviderSyncDiff.new(cache_manager: @cache_manager)
            @output = output
          end

          # Run the sync-providers workflow
          # @param config_dir [String, nil] Override config directory
          # @param provider [String, nil] Limit to specific provider
          # @param apply [Boolean] Apply changes to files
          # @param commit [Boolean] Commit changes via ace-git-commit
          # @param show_all [Boolean] Show all models regardless of release date
          # @param since [String, Date, nil] Only show models released after this date
          # @return [Hash] Result with status and details
          def sync(config_dir: nil, provider: nil, apply: false, commit: false, show_all: false, since: nil)
            # Ensure cache is fresh
            ensure_cache_fresh

            # Read current provider configs
            current_configs = Atoms::ProviderConfigReader.read_all(config_dir: config_dir)

            if current_configs.empty?
              return {
                status: :error,
                message: "No provider configs found. Check config directory."
              }
            end

            # Parse since date if provided
            since_date = parse_since_date(since)

            # Generate diff
            diff_results = @diff_generator.generate(
              current_configs,
              provider_filter: provider,
              since_date: since_date,
              show_all: show_all
            )

            # Build result
            result = {
              status: :ok,
              diff: diff_results,
              summary: @diff_generator.summary(diff_results),
              changes_detected: @diff_generator.any_changes?(diff_results),
              applied: false,
              committed: false,
              show_all: show_all,
              since_date: since_date
            }

            # Apply changes if requested
            if apply && result[:changes_detected]
              apply_result = apply_changes(diff_results, current_configs)
              result[:applied] = apply_result[:success]
              result[:apply_errors] = apply_result[:errors] if apply_result[:errors].any?

              # Commit if requested and apply succeeded
              if commit && result[:applied]
                result[:committed] = commit_changes(result[:summary])
              end
            end

            result
          end

          # Format diff results for display
          # @param result [Hash] Sync result
          # @return [String] Formatted output
          def format_result(result)
            lines = []
            lines << "Syncing provider configs with models.dev..."

            # Show date filter info
            if result[:show_all]
              lines << "(Showing all models)"
            elsif result[:since_date]
              lines << "(Showing models released after #{result[:since_date]})"
            end

            lines << ""

            result[:diff].each do |provider_name, diff|
              lines << format_provider_diff(provider_name, diff)
            end

            # Add summary
            summary = result[:summary]
            lines << ""
            lines << "Summary: #{summary[:added]} added, #{summary[:removed]} removed, " \
                     "#{summary[:unchanged]} unchanged across #{summary[:providers_synced]} providers"

            if summary[:deprecated] > 0
              lines << "  (#{summary[:deprecated]} deprecated models flagged)"
            end

            if summary[:providers_skipped] > 0
              lines << "  (#{summary[:providers_skipped]} providers not found in models.dev)"
            end

            # Add action hints
            lines << ""
            if result[:changes_detected]
              if result[:applied]
                lines << "Changes applied to config files."
                lines << if result[:committed]
                  "Changes committed."
                else
                  "Run with --commit to commit changes."
                end
              else
                lines << "Run with --apply to update config files."
              end
            else
              lines << "All providers are up to date."
            end

            unless result[:show_all]
              lines << "Run with --all to see all models (not just new releases)."
            end

            lines.join("\n")
          end

          private

          def parse_since_date(value)
            return nil unless value

            case value
            when Date
              value
            when String
              Date.parse(value)
            end
          rescue ArgumentError
            nil
          end

          def ensure_cache_fresh
            unless @cache_manager.exists?
              raise CacheError, "No models.dev cache found. Run 'ace-models sync' first."
            end

            unless @cache_manager.fresh?(max_age: PROVIDER_SYNC_CACHE_MAX_AGE)
              output.puts "Warning: models.dev cache is more than 7 days old. Consider running 'ace-models sync'."
            end
          end

          def apply_changes(diff_results, current_configs)
            errors = []
            success = true

            diff_results.each do |provider_name, diff|
              next unless diff[:status] == :ok
              next if diff[:added].empty? && diff[:removed].empty?

              begin
                config = current_configs[provider_name]
                source_file = config["_source_file"]

                unless source_file
                  errors << "#{provider_name}: No source file found"
                  success = false
                  next
                end

                # Calculate new model list
                current_models = Atoms::ProviderConfigReader.extract_models(config)
                new_models = (current_models + diff[:added] - diff[:removed]).uniq.sort

                # Create backup
                Atoms::ProviderConfigWriter.backup(source_file)

                # Update file with models and last_synced date
                Atoms::ProviderConfigWriter.update_models_and_sync_date(source_file, new_models)
                output.puts "Updated: #{source_file}"
              rescue ConfigError => e
                errors << "#{provider_name}: #{e.message}"
                success = false
              rescue => e
                errors << "#{provider_name}: Unexpected error: #{e.message}"
                success = false
              end
            end

            {success: success, errors: errors}
          end

          def commit_changes(summary)
            message = "chore(providers): Sync model lists with models.dev\n\n" \
                      "Added: #{summary[:added]} models\n" \
                      "Removed: #{summary[:removed]} models"

            # Try to use ace-git-commit if available
            begin
              system("ace-git-commit", "-m", message)
              $?.success?
            rescue Errno::ENOENT
              output.puts "Warning: ace-git-commit not found. Please commit changes manually."
              false
            end
          end

          def format_provider_diff(provider_name, diff)
            lines = []

            # Show models_dev_id mapping if different from provider name
            lines << if diff[:models_dev_id]
              "#{provider_name}: (mapped to #{diff[:models_dev_id]})"
            else
              "#{provider_name}:"
            end

            if diff[:status] == :not_found
              lines << "  ⚠ Provider not found in models.dev"
              if diff[:hint]
                lines << "    Hint: #{diff[:hint]}"
              end
              return lines.join("\n")
            end

            if diff[:added].empty? && diff[:removed].empty? && diff[:deprecated].empty?
              lines << "  = (no changes)"
              if diff[:last_synced]
                lines << "  Last synced: #{diff[:last_synced]}"
              end
              return lines.join("\n")
            end

            diff[:added].each do |model|
              release_date = diff[:added_with_dates]&.[](model)
              lines << if release_date
                "  + #{model.ljust(35)} (new, released: #{release_date})"
              else
                "  + #{model.ljust(35)} (new)"
              end
            end

            diff[:removed].each do |model|
              lines << "  - #{model.ljust(35)} (removed)"
            end

            diff[:deprecated].each do |model|
              lines << "  ! #{model.ljust(35)} (deprecated)"
            end

            if diff[:last_synced]
              lines << "  Last synced: #{diff[:last_synced]}"
            end

            lines << "" if diff[:added].any? || diff[:removed].any?

            lines.join("\n")
          end
        end
      end
    end
  end
end

# frozen_string_literal: true

module Ace
  module Git
    module Secrets
      module Commands
        # CLI command for revoking tokens via provider APIs
        class RevokeCommand
          # Execute revoke command
          # @param options [Hash] Command options
          # @return [Integer] Exit code (0=success, 1=partial/failure, 2=error)
          def self.execute(options)
            new(options).execute
          end

          def initialize(options)
            @options = options
          end

          def execute
            tokens = load_tokens
            return 1 if tokens.nil?

            if tokens.empty?
              puts "No tokens found to revoke."
              puts "Run 'ace-git-secrets scan' first to detect tokens."
              return 0
            end

            # Filter by service if specified
            services = @options[:service] ? [@options[:service]] : nil

            revoker = Molecules::TokenRevoker.new
            results = revoker.revoke_all(tokens, services: services)

            # Display results
            display_results(results)

            # Return code based on results
            if results.all?(&:success?)
              0
            elsif results.any?(&:success?)
              1 # Partial success
            else
              1
            end
          rescue => e
            puts "Error: #{e.message}"
            puts e.backtrace.first(5).join("\n") if ENV["DEBUG"]
            2
          end

          private

          def load_tokens
            if @options[:token]
              # Single token provided
              [create_token_from_value(@options[:token])]
            elsif @options[:scan_file]
              load_tokens_from_file
            else
              # Ensure gitleaks is available for scanning
              Atoms::GitleaksRunner.ensure_available!

              # Scan to find tokens
              scanner = Molecules::HistoryScanner.new(
                gitleaks_config: Ace::Git::Secrets.gitleaks_config_path
              )
              report = scanner.scan(min_confidence: "high")
              report.revocable_tokens
            end
          end

          def create_token_from_value(value)
            # Detect token type from prefix
            token_type = identify_token_type(value)

            Models::DetectedToken.new(
              token_type: token_type,
              pattern_name: token_type,
              confidence: "high",
              commit_hash: "manual",
              file_path: "manual_input",
              raw_value: value,
              detected_by: "manual"
            )
          end

          # Simple token type detection from value prefix
          # @param value [String] Token value
          # @return [String] Token type
          def identify_token_type(value)
            case value
            when /\Aghp_/ then "github_pat_classic"
            when /\Agho_/ then "github_oauth"
            when /\Aghs_/ then "github_app"
            when /\Aghr_/ then "github_refresh"
            when /\Agithub_pat_/ then "github_pat_fine"
            when /\Ask-ant-/ then "anthropic_api_key"
            when /\Ask-/ then "openai_api_key"
            when /\AAKIA/ then "aws_access_key"
            when /\AASIA/ then "aws_session"
            when /\AAIza/ then "google_api_key"
            when /\Axox[baprs]-/ then "slack_token"
            when /\Anpm_/ then "npm_token"
            else "unknown"
            end
          end

          def load_tokens_from_file
            require "json"

            file_path = @options[:scan_file]

            unless File.exist?(file_path)
              warn "Scan file not found: #{file_path}"
              return nil
            end

            content = File.read(file_path)
            data = JSON.parse(content)

            unless data.is_a?(Hash) && data["tokens"].is_a?(Array)
              warn "Invalid scan file format: expected {\"tokens\": [...]}"
              return nil
            end

            # Validate that raw_value is present - required for revocation
            tokens_without_raw = data["tokens"].select { |t| t["raw_value"].nil? || t["raw_value"].empty? }
            unless tokens_without_raw.empty?
              warn "Error: Scan file missing raw_value for #{tokens_without_raw.size} token(s)."
              warn "The scan file was likely saved without raw token values."
              warn "Re-run: ace-git-secrets scan  (saves with raw values by default)"
              return nil
            end

            data["tokens"].map do |t|
              Models::DetectedToken.new(
                token_type: t["token_type"],
                pattern_name: t["pattern_name"],
                confidence: t["confidence"],
                commit_hash: t["commit_hash"],
                file_path: t["file_path"],
                line_number: t["line_number"],
                raw_value: t["raw_value"],
                detected_by: t["detected_by"] || "scan_file"
              )
            end.select(&:revocable?)
          rescue JSON::ParserError => e
            warn "Invalid JSON in scan file: #{e.message}"
            nil
          rescue Errno::EACCES
            warn "Permission denied reading scan file: #{file_path}"
            nil
          rescue => e
            warn "Error loading scan file: #{e.class.name}: #{e.message}"
            nil
          end

          def display_results(results)
            puts "Token Revocation Results"
            puts "=" * 50
            puts

            results.each do |result|
              status_icon = case result.status
              when "revoked" then "[OK]"
              when "failed" then "[FAIL]"
              when "skipped" then "[SKIP]"
              else "[?]"
              end

              puts "#{status_icon} #{result.token.token_type}"
              puts "    Value: #{result.token.masked_value}"
              puts "    Service: #{result.service}"
              puts "    Status: #{result.status}"
              puts "    Message: #{result.message}"
              puts
            end

            # Summary
            revoked = results.count(&:success?)
            failed = results.count(&:failed?)
            skipped = results.count(&:skipped?)

            puts "-" * 50
            puts "Summary: #{revoked} revoked, #{failed} failed, #{skipped} skipped"

            if skipped > 0
              puts
              puts "Note: Some tokens require manual revocation."
              puts "Visit the provider dashboards to revoke them."
            end
          end
        end
      end
    end
  end
end

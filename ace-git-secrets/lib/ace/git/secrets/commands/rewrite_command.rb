# frozen_string_literal: true

module Ace
  module Git
    module Secrets
      module Commands
        # CLI command for rewriting Git history to remove tokens
        class RewriteCommand
          # Execute rewrite-history command
          # @param options [Hash] Command options
          # @return [Integer] Exit code (0=success, 1=failure, 2=error)
          def self.execute(options)
            new(options).execute
          end

          def initialize(options)
            @options = options
          end

          def execute
            # Ensure gitleaks is available
            Atoms::GitleaksRunner.ensure_available!

            cleaner = Organisms::HistoryCleaner.new(
              repository_path: ".",
              gitleaks_config: Ace::Git::Secrets.gitleaks_config_path
            )

            # Load tokens from scan file if provided
            tokens = load_tokens_from_file if @options[:scan_file]
            return 1 if @options[:scan_file] && tokens.nil?

            # First pass - get confirmation requirements
            result = cleaner.clean(
              tokens: tokens,
              dry_run: @options[:dry_run],
              force: @options[:force],
              create_backup: @options.fetch(:backup, true)
            )

            # Handle dry run
            if result[:dry_run]
              puts "DRY RUN - No changes made"
              puts
              puts result[:message]

              if result[:tokens]
                puts
                puts "Tokens that would be removed:"
                result[:tokens].each do |t|
                  puts "  - #{t[:type]}: #{t[:masked_value]} (#{t[:file]}:#{t[:commit]})"
                end
              end
              return 0
            end

            # Handle confirmation required
            if result[:requires_confirmation]
              puts result[:message]
              print "\nConfirmation: "

              input = $stdin.gets&.strip

              unless cleaner.valid_confirmation?(input)
                puts "\nConfirmation failed. No changes made."
                return 1
              end

              # Re-run with force after confirmation
              result = cleaner.clean(
                tokens: tokens,
                force: true,
                create_backup: @options.fetch(:backup, true)
              )
            end

            # Handle result
            if result[:success]
              puts result[:message]
              puts result[:next_steps] if result[:next_steps]
              0
            else
              puts "Error: #{result[:message]}"
              1
            end
          rescue => e
            puts "Error: #{e.message}"
            puts e.backtrace.first(5).join("\n") if ENV["DEBUG"]
            2
          end

          private

          def load_tokens_from_file
            return nil unless @options[:scan_file]

            require "json"
            file_path = @options[:scan_file]

            unless File.exist?(file_path)
              warn "Scan file not found: #{file_path}"
              return nil
            end

            data = JSON.parse(File.read(file_path))

            unless data.is_a?(Hash) && data["tokens"].is_a?(Array)
              warn "Invalid scan file format: expected {\"tokens\": [...]}"
              return nil
            end

            # Validate that raw_value is present - required for history rewriting
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
            end
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
        end
      end
    end
  end
end

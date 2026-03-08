# frozen_string_literal: true

module Ace
  module GitCommit
    module Molecules
      # SplitCommitExecutor performs sequential commits with rollback support
      class SplitCommitExecutor
        # Reference the default scope name constant
        DEFAULT_SCOPE_NAME = Ace::Support::Config::Models::ConfigGroup::DEFAULT_SCOPE_NAME
        def initialize(git_executor:, diff_analyzer:, file_stager:, message_generator:)
          @git = git_executor
          @diff_analyzer = diff_analyzer
          @file_stager = file_stager
          @message_generator = message_generator
        end

        # Execute split commits
        # @param groups [Array<Models::CommitGroup>] Commit groups
        # @param options [Models::CommitOptions] Options
        # @return [Models::SplitCommitResult] Result
        def execute(groups, options)
          original_head = current_head
          result = Models::SplitCommitResult.new(original_head: original_head)

          # Pre-generate all messages in batch if using LLM (includes ordering)
          if options.use_llm?
            batch_result = generate_batch_messages(groups, options)
            ordered_groups, messages = reorder_groups_by_llm(groups, batch_result)
          else
            ordered_groups = groups
            messages = Array.new(groups.length) { options.message }
          end

          ordered_groups.each_with_index do |group, index|
            label = group.scope_name.to_s.empty? ? DEFAULT_SCOPE_NAME : group.scope_name
            puts "[#{index + 1}/#{ordered_groups.length}] Committing #{label} changes..." unless options.quiet

            unless @file_stager.stage_paths(group.files, quiet: options.quiet)
              error_msg = @file_stager.last_error || "Failed to stage files"
              result.add_failure(group, error_msg)
              unless options.quiet
                warn "✗ Failed to stage files for scope '#{label}':"
                warn "  #{error_msg}"
              end
              rollback_to(original_head, result, options)
              return result
            end

            # Check if all files were gitignored - skip commit for this group
            if @file_stager.all_files_skipped?
              unless options.quiet
                puts "✓ No files to commit for scope '#{label}' (all gitignored)"
              end
              result.add_skipped(group, "All files gitignored")
              next
            end

            message = messages[index]

            if options.dry_run
              show_group_dry_run(message, group)
              result.add_dry_run(group)
              next
            end

            commit_sha = perform_commit(message, options)
            result.add_success(group, commit_sha)
          rescue GitError => e
            scope_label = group.scope_name.to_s.empty? ? DEFAULT_SCOPE_NAME : group.scope_name
            error_msg = "Failed to commit scope '#{scope_label}': #{e.message}"
            result.add_failure(group, error_msg)
            unless options.quiet
              warn "✗ #{error_msg}"
            end
            rollback_to(original_head, result, options)
            return result
          end

          result
        end

        private

        def generate_batch_messages(groups, options)
          puts "Generating commit messages for #{groups.length} scopes..." unless options.quiet

          # Collect context for all groups using read-only diffs
          # IMPORTANT: We use get_all_diff with file paths instead of staging files
          # This preserves any user-selected hunks from partial staging (git add -p)
          groups_context = groups.map do |group|
            # Get diff for specific files without modifying the index
            diff = @diff_analyzer.get_all_diff(group.files)
            files = group.files

            # Extract config values using normalized access
            config = normalize_config_keys(group.config)
            {
              scope_name: group.scope_name,
              diff: diff,
              files: files,
              type_hint: config["type_hint"],
              description: config["description"],
              model: config["model"]
            }
          end

          # Check if all groups use the same model (can batch) or need segmentation
          models_used = groups_context.map { |ctx| ctx[:model] }.compact.uniq
          cli_model = options.model

          if cli_model
            # CLI flag overrides all group models - can batch
            config_override = { "model" => cli_model }
            return @message_generator.generate_batch(
              groups_context,
              intention: options.intention,
              config: config_override
            )
          elsif models_used.length <= 1
            # All groups use same model (or no model) - can batch
            config_override = models_used.first ? { "model" => models_used.first } : {}
            return @message_generator.generate_batch(
              groups_context,
              intention: options.intention,
              config: config_override
            )
          end

          # Different models per scope - generate sequentially by model
          generate_segmented_by_model(groups_context, options.intention)
        rescue Error => e
          warn "[ace-git-commit] Batch generation failed, falling back to per-scope generation: #{e.message}" unless options.quiet
          generate_per_scope_messages(groups_context, options)
        end

        # Generate messages segmented by model when groups have different model configs
        def generate_segmented_by_model(groups_context, intention)
          messages_by_scope = {}

          # Group contexts by their model
          by_model = groups_context.group_by { |ctx| ctx[:model] || "default" }

          by_model.each do |model, contexts|
            config_override = model == "default" ? {} : { "model" => model }
            result = @message_generator.generate_batch(
              contexts,
              intention: intention,
              config: config_override
            )

            # Map messages back to scope names
            result[:order].each_with_index do |scope, idx|
              messages_by_scope[scope] = result[:messages][idx]
            end
          end

          # Rebuild in original order
          ordered_messages = groups_context.map { |ctx| messages_by_scope[ctx[:scope_name]] }
          { messages: ordered_messages, order: groups_context.map { |ctx| ctx[:scope_name] } }
        end

        # Normalize config keys to strings for consistent access
        def normalize_config_keys(config)
          return {} unless config.is_a?(Hash)

          config.transform_keys(&:to_s)
        end

        def reorder_groups_by_llm(groups, batch_result)
          messages = batch_result[:messages]
          order = batch_result[:order]

          # Align groups with messages using the order array
          # batch_result[:order] contains scope names matching batch_result[:messages]
          groups_by_scope = groups.to_h { |g| [g.scope_name, g] }
          aligned_groups = order.map { |scope| groups_by_scope[scope] }.compact

          # Handle any groups that weren't in the LLM response (fallback)
          missing_groups = groups.reject { |g| order.include?(g.scope_name) }
          aligned_groups.concat(missing_groups)

          # Extend messages array for missing groups by mapping from scope->message.
          message_by_scope = order.each_with_index.to_h { |scope, idx| [scope, messages[idx]] }
          aligned_messages = aligned_groups.map { |g| message_by_scope[g.scope_name] }
          if aligned_messages.any?(&:nil?)
            missing = aligned_groups.each_with_index.filter_map { |g, idx| g.scope_name if aligned_messages[idx].nil? }
            raise Error, "Missing generated message(s) for scope(s): #{missing.join(', ')}"
          end

          # Always sort by commit type - more reliable than LLM ordering
          sort_by_commit_type(aligned_groups, aligned_messages)
        end

        def generate_per_scope_messages(groups_context, options)
          messages = groups_context.map do |ctx|
            config = {}
            config["model"] = options.model if options.model
            config["model"] = ctx[:model] if options.model.nil? && ctx[:model]

            @message_generator.generate(
              ctx[:diff],
              intention: options.intention,
              files: ctx[:files],
              config: config
            )
          end

          { messages: messages, order: groups_context.map { |ctx| ctx[:scope_name] } }
        end

        def sort_by_commit_type(groups, messages)
          # Type priority: feat/fix first, then refactor/test, then chore, then docs last
          type_priority = {
            "feat" => 0, "fix" => 1, "refactor" => 2, "test" => 3,
            "perf" => 4, "chore" => 5, "style" => 6, "docs" => 7
          }

          # Pair groups with messages and extract types
          pairs = groups.zip(messages).map do |group, msg|
            type = msg.to_s.match(/^(\w+)[\(:]/)&.[](1) || "chore"
            { group: group, message: msg, type: type, priority: type_priority[type] || 5 }
          end

          # Sort by priority
          sorted = pairs.sort_by { |p| [p[:priority], p[:group].scope_name] }

          [sorted.map { |p| p[:group] }, sorted.map { |p| p[:message] }]
        end

        def show_group_dry_run(message, group)
          puts "-" * 40
          puts "Scope: #{group.scope_name}"
          puts "Files:"
          group.files.each { |file| puts "  #{file}" }
          puts "\nMessage:"
          puts message
          puts "-" * 40
        end

        def perform_commit(message, options)
          puts "Committing..." unless options.quiet
          @git.execute("commit", "-m", message)
          commit_sha = @git.execute("rev-parse", "HEAD").strip

          unless options.quiet
            summarizer = Molecules::CommitSummarizer.new(@git)
            summary = summarizer.summarize(commit_sha)
            puts summary
          end

          commit_sha
        end

        def current_head
          @git.execute("rev-parse", "HEAD").strip
        rescue GitError
          nil
        end

        def rollback_to(original_head, result, options)
          return if original_head.nil?

          @git.execute("reset", "--soft", original_head)
          puts "Rolled back split commit operation." unless options.quiet
        rescue GitError => e
          result.mark_rollback_error(e.message)
          warn "Rollback failed: #{e.message}"
        end
      end
    end
  end
end

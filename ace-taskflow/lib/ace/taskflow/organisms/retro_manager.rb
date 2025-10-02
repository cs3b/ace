# frozen_string_literal: true

require "fileutils"
require "time"
require_relative "../molecules/retro_loader"
require_relative "../molecules/release_resolver"
require_relative "../molecules/config_loader"

module Ace
  module Taskflow
    module Organisms
      # Retro (reflection note) business logic orchestration
      class RetroManager
        RETRO_TEMPLATE = <<~TEMPLATE
          # Reflection: [Topic/Date]

          **Date**: %{date}
          **Context**: [Brief description of what this reflection covers]
          **Author**: [Name or identifier]
          **Type**: [Standard | Conversation Analysis | Self-Review]

          ## What Went Well

          - [Positive outcome or successful approach]
          - [Effective pattern discovered]
          - [Good decision that paid off]

          ## What Could Be Improved

          - [Challenge encountered]
          - [Inefficiency identified]
          - [Area needing attention]

          ## Key Learnings

          - [Important insight gained]
          - [New understanding developed]
          - [Valuable lesson learned]

          ## Conversation Analysis (For conversation-based reflections)

          ### Challenge Patterns Identified

          #### High Impact Issues

          - **[Challenge Type]**: [Description]
            - Occurrences: [Number of times this pattern appeared]
            - Impact: [Description of delays/rework caused]
            - Root Cause: [Analysis of underlying issue]

          #### Medium Impact Issues

          - **[Challenge Type]**: [Description]
            - Occurrences: [Number of times this pattern appeared]
            - Impact: [Description of inefficiencies caused]

          #### Low Impact Issues

          - **[Challenge Type]**: [Description]
            - Occurrences: [Number of times this pattern appeared]
            - Impact: [Minor inconveniences]

          ### Improvement Proposals

          #### Process Improvements

          - [Specific workflow enhancement]
          - [Documentation improvement]
          - [Better validation step]

          #### Tool Enhancements

          - [Command improvement suggestion]
          - [Tool capability request]
          - [Automation opportunity]

          #### Communication Protocols

          - [Clearer requirement gathering]
          - [Better confirmation process]
          - [Enhanced feedback loop]

          ### Token Limit & Truncation Issues

          - **Large Output Instances**: [Count and description]
          - **Truncation Impact**: [Information lost, workflow disruption]
          - **Mitigation Applied**: [How issues were resolved]
          - **Prevention Strategy**: [Future avoidance approach]

          ## Action Items

          ### Stop Doing

          - [Practice or approach to discontinue]
          - [Ineffective pattern to avoid]

          ### Continue Doing

          - [Successful practice to maintain]
          - [Effective approach to keep using]

          ### Start Doing

          - [New practice to adopt]
          - [Improvement to implement]

          ## Technical Details

          (Optional: Specific technical insights, code patterns, or implementation notes)

          ## Additional Context

          (Optional: Links to relevant PRs, tasks, or documentation)
        TEMPLATE

        attr_reader :root_path, :config

        def initialize(config = nil)
          @config = config || Molecules::ConfigLoader.load
          @root_path = Molecules::ConfigLoader.find_root
          @retro_loader = Molecules::RetroLoader.new(@root_path)
          @release_resolver = Molecules::ReleaseResolver.new(@root_path)
        end

        # Create new retro file with template
        # @param title [String] Retro title for filename
        # @param context [String] Context to create in (current, backlog, specific release)
        # @return [Hash] Result with :success, :message, :path
        def create_retro(title, context: "current")
          # Resolve context to retro directory
          retro_dir = @retro_loader.resolve_retro_directory(context)
          unless retro_dir
            return { success: false, message: "Invalid context: #{context}" }
          end

          # Ensure retro directory exists
          FileUtils.mkdir_p(retro_dir)

          # Generate filename with date and slug
          date_str = Time.now.strftime("%Y-%m-%d")
          slug = generate_slug(title)
          filename = "#{date_str}-#{slug}.md"
          file_path = File.join(retro_dir, filename)

          # Check if file already exists
          if File.exist?(file_path)
            return {
              success: false,
              message: "Retro file already exists: #{filename}"
            }
          end

          begin
            # Generate content from template
            content = RETRO_TEMPLATE % { date: date_str }

            # Write file
            File.write(file_path, content)

            {
              success: true,
              message: "Reflection note created: #{filename}",
              path: file_path
            }
          rescue StandardError => e
            { success: false, message: "Failed to create retro: #{e.message}" }
          end
        end

        # Load retro by reference
        # @param reference [String] Retro reference (filename or partial match)
        # @param context [String] Context to search
        # @return [Hash, nil] Retro data or nil
        def load_retro(reference, context: "current")
          @retro_loader.find_retro_by_reference(reference, context: context)
        end

        # List retros with filtering
        # @param context [String] Context to list from
        # @param filters [Hash] Filter criteria (:scope => :active, :done, :all)
        # @return [Array<Hash>] Filtered retros
        def list_retros(context: "current", filters: {})
          scope = filters[:scope] || :active

          case scope
          when :active
            @retro_loader.list_active_retros(context: context)
          when :done
            @retro_loader.list_done_retros(context: context)
          when :all
            @retro_loader.list_all_retros(context: context)
          else
            @retro_loader.list_active_retros(context: context)
          end
        end

        # Mark retro as done by moving to done/ subfolder
        # @param reference [String] Retro reference
        # @param context [String] Context to search
        # @return [Hash] Result with :success and :message
        def mark_retro_done(reference, context: "current")
          # Find the retro
          retro = load_retro(reference, context: context)
          unless retro
            return { success: false, message: "Retro '#{reference}' not found" }
          end

          # Check if already done
          if retro[:is_done]
            return {
              success: false,
              message: "Retro '#{reference}' is already marked as done"
            }
          end

          # Determine source and destination paths
          source_path = retro[:path]
          retro_dir = File.dirname(source_path)
          done_dir = File.join(retro_dir, "done")
          dest_path = File.join(done_dir, File.basename(source_path))

          begin
            # Ensure done directory exists
            FileUtils.mkdir_p(done_dir)

            # Move file to done/
            FileUtils.mv(source_path, dest_path)

            {
              success: true,
              message: "Retro '#{reference}' marked as done and moved to done/",
              path: dest_path
            }
          rescue StandardError => e
            { success: false, message: "Failed to move retro: #{e.message}" }
          end
        end

        private

        def generate_slug(title)
          title
            .downcase
            .gsub(/[^a-z0-9\s-]/, "")  # Remove special chars
            .gsub(/\s+/, "-")          # Replace spaces with hyphens
            .gsub(/-+/, "-")           # Collapse multiple hyphens
            .gsub(/^-|-$/, "")         # Remove leading/trailing hyphens
        end
      end
    end
  end
end

# frozen_string_literal: true

require "json"

module Ace
  module Taskflow
    module Molecules
      # Generates hierarchical slugs using LLM with fallback to existing generators
      class LlmSlugGenerator
        # Goal type keywords for consistent naming
        GOAL_TYPES = %w[add enhance fix refactor].freeze

        def initialize(debug: false)
          @debug = debug
        end

        # Generate hierarchical slugs for a task
        # @param title [String] Task title
        # @param context [Hash] Additional context (project_name, type, etc.)
        # @return [Hash] { folder_slug:, file_slug:, success:, source: } or fallback result
        def generate_task_slugs(title, context = {})
          # Try LLM generation first
          llm_result = try_llm_task_generation(title, context)
          return llm_result if llm_result[:success]

          # Fallback to existing logic
          debug_log("LLM generation failed, using fallback")
          fallback_task_generation(title, context)
        end

        # Generate hierarchical slugs for an idea
        # @param description [String] Idea description/content
        # @param context [Hash] Additional context (project_name, timestamp, etc.)
        # @return [Hash] { folder_slug:, file_slug:, success:, source: } or fallback result
        def generate_idea_slugs(description, context = {})
          # Try LLM generation first
          llm_result = try_llm_idea_generation(description, context)
          return llm_result if llm_result[:success]

          # Fallback to existing logic
          debug_log("LLM generation failed, using fallback")
          fallback_idea_generation(description, context)
        end

        private

        def load_slug_prompt
          require "open3"

          # Load prompt via ace-nav protocol
          stdout, stderr, status = Open3.capture3("ace-nav", "prompt://slug-generation", "--content")

          if status.success?
            debug_log("Successfully loaded slug-generation prompt via ace-nav")
            stdout.strip
          else
            # Fallback to reading file directly from handbook
            prompt_path = File.join(gem_root, "handbook/prompts/slug-generation.md")
            if File.exist?(prompt_path)
              debug_log("Loaded slug-generation prompt from file (ace-nav unavailable)")
              File.read(prompt_path)
            else
              raise "Slug generation prompt not found via ace-nav or file system"
            end
          end
        rescue StandardError => e
          debug_log("Error loading slug prompt: #{e.message}")
          raise "Failed to load slug generation prompt: #{e.message}"
        end

        def gem_root
          File.expand_path("../../..", __dir__)
        end

        def try_llm_task_generation(title, context)
          # Build prompt for task slug generation
          prompt = build_task_slug_prompt(title, context)

          # Call LLM
          result = call_llm(prompt)
          return { success: false } unless result[:success]

          # Parse JSON response
          parsed = parse_llm_response(result[:text])
          return { success: false } unless parsed

          # Validate and return
          if valid_task_slugs?(parsed)
            {
              success: true,
              folder_slug: parsed["folder_slug"],
              file_slug: parsed["file_slug"],
              source: :llm
            }
          else
            debug_log("LLM returned invalid slug format: #{parsed.inspect}")
            { success: false }
          end
        rescue StandardError => e
          debug_log("LLM task generation error: #{e.message}")
          { success: false }
        end

        def try_llm_idea_generation(description, context)
          # Build prompt for idea slug generation
          prompt = build_idea_slug_prompt(description, context)

          # Call LLM
          result = call_llm(prompt)
          return { success: false } unless result[:success]

          # Parse JSON response
          parsed = parse_llm_response(result[:text])
          return { success: false } unless parsed

          # Validate and return
          if valid_idea_slugs?(parsed)
            {
              success: true,
              folder_slug: parsed["folder_slug"],
              file_slug: parsed["file_slug"],
              source: :llm
            }
          else
            debug_log("LLM returned invalid slug format: #{parsed.inspect}")
            { success: false }
          end
        rescue StandardError => e
          debug_log("LLM idea generation error: #{e.message}")
          { success: false }
        end

        def call_llm(prompt)
          require "ace/llm/query_interface"
          # Workaround for missing require in ace-llm
          require "ace/llm/molecules/llm_alias_resolver"

          # Log the prompt being sent to LLM
          debug_log("=== LLM PROMPT ===")
          debug_log(prompt)
          debug_log("=== END PROMPT ===")

          # Use glite (Gemini 2.0 Flash Lite) as default - fast and cheap
          response = Ace::LLM::QueryInterface.query(
            "glite",
            prompt,
            temperature: 0.3,  # Lower temperature for more consistent output
            max_tokens: 500,   # Increased for context-aware responses
            debug: @debug
          )

          # Log the response from LLM
          debug_log("=== LLM RESPONSE ===")
          debug_log(response[:text])
          debug_log("=== END RESPONSE ===")

          { success: true, text: response[:text] }
        rescue StandardError => e
          debug_log("LLM call failed: #{e.message}")
          { success: false, error: e.message }
        end

        def parse_llm_response(text)
          # Extract JSON from response (LLM might add markdown code blocks)
          json_text = text.strip
          json_text = json_text.gsub(/^```json\s*\n?/, "").gsub(/\n?```$/, "") if json_text.include?("```")

          JSON.parse(json_text)
        rescue JSON::ParserError => e
          debug_log("Failed to parse LLM JSON response: #{e.message}")
          nil
        end

        def build_task_slug_prompt(title, context)
          # Load prompt template via ace-nav protocol
          prompt_template = load_slug_prompt

          # Append task-specific details to the prompt
          <<~PROMPT
            #{prompt_template}

            ---

            ## Task Details

            **Task Title**: #{title}
            **Additional Context**: #{context.to_json}

            Generate the hierarchical slugs for this task.
          PROMPT
        end

        def build_idea_slug_prompt(description, context)
          # Load prompt template via ace-nav protocol
          prompt_template = load_slug_prompt

          # Extract first 1000 chars for context
          desc_preview = description[0..1000]

          # Append idea-specific details to the prompt
          <<~PROMPT
            #{prompt_template}

            ---

            ## Idea Details

            **Idea Description**: #{desc_preview}
            **Additional Context**: #{context.to_json}

            Generate the hierarchical slugs for this idea.
          PROMPT
        end

        def valid_task_slugs?(parsed)
          return false unless parsed.is_a?(Hash)
          return false unless parsed["folder_slug"].is_a?(String)
          return false unless parsed["file_slug"].is_a?(String)
          return false if parsed["folder_slug"].empty?
          return false if parsed["file_slug"].empty?

          # Validate format (lowercase, hyphens only)
          folder_valid = parsed["folder_slug"] =~ /^[a-z0-9]+(-[a-z0-9]+)*$/
          file_valid = parsed["file_slug"] =~ /^[a-z0-9]+(-[a-z0-9]+)*$/

          folder_valid && file_valid
        end

        def valid_idea_slugs?(parsed)
          # Same validation as task slugs
          valid_task_slugs?(parsed)
        end

        def fallback_task_generation(title, context)
          require_relative "task_slug_generator"

          # Use existing TaskSlugGenerator
          slug_part = TaskSlugGenerator.generate_descriptive_part(title, context)

          # Split into folder and file parts (simple heuristic)
          # Take first 2-3 words for folder, rest for file
          parts = slug_part.split("-")
          folder_parts = parts.take(3)
          file_parts = parts.drop(3)

          folder_slug = folder_parts.join("-")
          file_slug = file_parts.any? ? file_parts.join("-") : folder_slug

          {
            success: true,
            folder_slug: folder_slug,
            file_slug: file_slug,
            source: :fallback
          }
        end

        def fallback_idea_generation(description, context)
          require_relative "file_namer"

          # Extract title from description
          title = description.split("\n").first || description
          title = title[0..49] if title.length > 50

          # Sanitize to create slug
          file_slug = title.to_s.downcase
                          .gsub(/[^\w\s-]/, "")
                          .gsub(/[\s_]+/, "-")
                          .gsub(/-+/, "-")
                          .gsub(/^-|-$/, "")
                          .strip

          # For folder, try to extract area from keywords
          area = extract_area_from_content(description)
          goal_type = extract_goal_type_from_content(description)
          folder_slug = [area, goal_type].compact.join("-")
          folder_slug = file_slug if folder_slug.empty?

          {
            success: true,
            folder_slug: folder_slug,
            file_slug: file_slug,
            source: :fallback
          }
        end

        def extract_area_from_content(content)
          content_lower = content.downcase

          # Common areas
          areas = %w[taskflow search docs git llm nav review lint test]
          areas.find { |area| content_lower.include?(area) }
        end

        def extract_goal_type_from_content(content)
          content_lower = content.downcase

          return "add" if content_lower =~ /\b(add|create|implement|new)\b/
          return "enhance" if content_lower =~ /\b(enhance|improve|update|upgrade)\b/
          return "fix" if content_lower =~ /\b(fix|repair|resolve|correct)\b/
          return "refactor" if content_lower =~ /\b(refactor|restructure|reorganize)\b/

          "enhance"  # Default
        end

        def debug_log(message)
          $stderr.puts "[LlmSlugGenerator] #{message}" if @debug
        end
      end
    end
  end
end

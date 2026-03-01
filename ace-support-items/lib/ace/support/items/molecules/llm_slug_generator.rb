# frozen_string_literal: true

require "json"

module Ace
  module Support
    module Items
      module Molecules
        # Generates hierarchical slugs using LLM with fallback to deterministic generation.
        # Soft dependency on ace-llm — gracefully falls back if not available.
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
            llm_result = try_llm_task_generation(title, context)
            return llm_result if llm_result[:success]

            debug_log("LLM generation failed, using fallback")
            fallback_task_generation(title, context)
          end

          # Generate hierarchical slugs for an idea
          # @param description [String] Idea description/content
          # @param context [Hash] Additional context
          # @return [Hash] { folder_slug:, file_slug:, success:, source: } or fallback result
          def generate_idea_slugs(description, context = {})
            llm_result = try_llm_idea_generation(description, context)
            return llm_result if llm_result[:success]

            debug_log("LLM generation failed, using fallback")
            fallback_idea_generation(description, context)
          end

          private

          def load_slug_prompt
            require "open3"

            stdout, _stderr, status = Open3.capture3("ace-nav", "prompt://slug-generation", "--content")

            if status.success?
              debug_log("Successfully loaded slug-generation prompt via ace-nav")
              stdout.strip
            else
              raise "Slug generation prompt not found via ace-nav"
            end
          rescue StandardError => e
            debug_log("Error loading slug prompt: #{e.message}")
            raise "Failed to load slug generation prompt: #{e.message}"
          end

          def try_llm_task_generation(title, context)
            prompt = build_task_slug_prompt(title, context)
            result = call_llm(prompt)
            return { success: false } unless result[:success]

            parsed = parse_llm_response(result[:text])
            return { success: false } unless parsed

            if valid_slugs?(parsed)
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
            prompt = build_idea_slug_prompt(description, context)
            result = call_llm(prompt)
            return { success: false } unless result[:success]

            parsed = parse_llm_response(result[:text])
            return { success: false } unless parsed

            if valid_slugs?(parsed)
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
            # Soft dependency on ace-llm
            require "ace/llm/query_interface"
            require "ace/llm/molecules/llm_alias_resolver"

            debug_log("=== LLM PROMPT ===")
            debug_log(prompt)
            debug_log("=== END PROMPT ===")

            response = Ace::LLM::QueryInterface.query(
              "glite",
              prompt,
              temperature: 0.3,
              max_tokens: 500,
              debug: @debug
            )

            debug_log("=== LLM RESPONSE ===")
            debug_log(response[:text])
            debug_log("=== END RESPONSE ===")

            { success: true, text: response[:text] }
          rescue LoadError => e
            debug_log("ace-llm not available: #{e.message}")
            { success: false, error: e.message }
          rescue StandardError => e
            debug_log("LLM call failed: #{e.message}")
            { success: false, error: e.message }
          end

          def parse_llm_response(text)
            json_text = text.strip
            json_text = json_text.gsub(/^```json\s*\n?/, "").gsub(/\n?```$/, "") if json_text.include?("```")

            JSON.parse(json_text)
          rescue JSON::ParserError => e
            debug_log("Failed to parse LLM JSON response: #{e.message}")
            nil
          end

          def build_task_slug_prompt(title, context)
            prompt_template = load_slug_prompt

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
            prompt_template = load_slug_prompt
            desc_preview = description[0..1000]

            <<~PROMPT
              #{prompt_template}

              ---

              ## Idea Details

              **Idea Description**: #{desc_preview}
              **Additional Context**: #{context.to_json}

              Generate the hierarchical slugs for this idea.
            PROMPT
          end

          def valid_slugs?(parsed)
            return false unless parsed.is_a?(Hash)
            return false unless parsed["folder_slug"].is_a?(String)
            return false unless parsed["file_slug"].is_a?(String)
            return false if parsed["folder_slug"].empty?
            return false if parsed["file_slug"].empty?

            folder_valid = parsed["folder_slug"] =~ /^[a-z0-9]+(-[a-z0-9]+)*$/
            file_valid = parsed["file_slug"] =~ /^[a-z0-9]+(-[a-z0-9]+)*$/

            folder_valid && file_valid
          end

          def fallback_task_generation(title, _context)
            slug = sanitize_to_slug(title)
            parts = slug.split("-")
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

          def fallback_idea_generation(description, _context)
            title = description.split("\n").first || description
            title = title[0..49] if title.length > 50
            file_slug = sanitize_to_slug(title)

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

          def sanitize_to_slug(text)
            text.to_s.downcase
                .gsub(/[^\w\s-]/, "")
                .gsub(/[\s_]+/, "-")
                .gsub(/-+/, "-")
                .gsub(/^-|-$/, "")
                .strip
          end

          def extract_area_from_content(content)
            content_lower = content.downcase
            areas = %w[taskflow search docs git llm nav review lint test]
            areas.find { |area| content_lower.include?(area) }
          end

          def extract_goal_type_from_content(content)
            content_lower = content.downcase

            return "add" if content_lower =~ /\b(add|create|implement|new)\b/
            return "enhance" if content_lower =~ /\b(enhance|improve|update|upgrade)\b/
            return "fix" if content_lower =~ /\b(fix|repair|resolve|correct)\b/
            return "refactor" if content_lower =~ /\b(refactor|restructure|reorganize)\b/

            "enhance"
          end

          def debug_log(message)
            $stderr.puts "[LlmSlugGenerator] #{message}" if @debug
          end
        end
      end
    end
  end
end

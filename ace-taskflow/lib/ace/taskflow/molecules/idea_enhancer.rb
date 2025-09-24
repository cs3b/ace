# frozen_string_literal: true

require "open3"
require "json"
require "yaml"
require "tempfile"

module Ace
  module Taskflow
    module Molecules
      # Enhances ideas with implementation details and context
      # Uses llm-query with embedded project context
      class IdeaEnhancer
        def initialize(debug: false, config: {})
          @debug = debug
          @config = config
        end

        # Enhance an idea with additional context and details
        # @param content [String] The original idea content
        # @param context [Hash] Additional context (project info, location, etc.)
        # @return [Hash] Enhanced content with metadata
        def enhance(content, context = {})
          debug_log("Enhancing idea with LLM")
          debug_log("Context: #{context.inspect}") if context.any?

          # Try LLM enhancement first, fall back to stub if unavailable
          if llm_available?
            result = enhance_with_llm(content, context)
            if result[:success]
              return result
            else
              debug_log("LLM enhancement failed: #{result[:error]}, falling back to stub")
            end
          else
            debug_log("llm-query not available, using stub implementation")
          end

          # Fallback to stub
          enhanced_content = generate_enhanced_stub(content, context)
          { success: true, content: enhanced_content }
        end

        private

        def generate_enhanced_stub(content, context)
          # Extract title from first line or first 50 chars
          title = extract_title(content)

          # Build enhanced version with placeholder sections
          enhanced = []
          enhanced << "# #{title}"
          enhanced << ""
          enhanced << "## Description"
          enhanced << ""
          enhanced << content.strip
          enhanced << ""

          # Add stub sections that would be filled by LLM
          enhanced << "## Implementation Approach"
          enhanced << ""
          enhanced << "_[This section will be enhanced with LLM integration]_"
          enhanced << ""
          enhanced << "- Analyze requirements"
          enhanced << "- Design solution architecture"
          enhanced << "- Implement core functionality"
          enhanced << "- Add tests and documentation"
          enhanced << ""

          enhanced << "## Technical Considerations"
          enhanced << ""
          enhanced << "_[This section will be enhanced with LLM integration]_"
          enhanced << ""
          enhanced << "- Dependencies and integrations"
          enhanced << "- Performance implications"
          enhanced << "- Security considerations"
          enhanced << ""

          if context[:location]
            enhanced << "## Context"
            enhanced << ""
            enhanced << "- Location: #{context[:location]}"
            enhanced << "- Created: #{Time.now.strftime('%Y-%m-%d %H:%M:%S')}"
            enhanced << ""
          end

          enhanced.join("\n")
        end

        def extract_title(content)
          # Take first line or first 50 chars
          first_line = content.split("\n").first || content
          title = first_line.strip
          title = title[0..49] + "..." if title.length > 50
          title
        end

        def debug_log(message)
          puts "Debug [IdeaEnhancer]: #{message}" if @debug
        end

        # Enhance idea using LLM with project context
        def enhance_with_llm(content, context)
          # Build system prompt with embedded context
          system_prompt = build_system_prompt_with_context

          # Prepare user prompt
          prompt = "Enhance this idea for the ACE project:\n\n#{content}"

          # Call llm-query
          result = call_llm_query(prompt, system_prompt, context)

          if result[:success]
            format_enhanced_idea(result[:data], content, context)
          else
            { success: false, error: result[:error] }
          end
        rescue => e
          { success: false, error: e.message }
        end

        def build_system_prompt_with_context
          template_path = File.join(gem_root, "templates/idea_enhancement.system.md")

          unless File.exist?(template_path)
            debug_log("System prompt template not found: #{template_path}")
            return default_system_prompt
          end

          # Read the template
          template = File.read(template_path)

          # Parse frontmatter to get configuration
          if template =~ /^---\n(.*?)\n---\n(.*)/m
            frontmatter = YAML.load($1)
            prompt_body = $2

            # Embed context if configured
            if frontmatter["embed_context"] && frontmatter["context_preset"]
              debug_log("Fetching ace-context preset: #{frontmatter["context_preset"]}")
              project_context = fetch_ace_context(frontmatter["context_preset"])
              prompt_body = prompt_body.gsub("{project_context}", project_context)
              debug_log("System prompt length with context: #{prompt_body.length} chars")
            end

            return prompt_body
          else
            return template
          end
        end

        def fetch_ace_context(preset)
          stdout, stderr, status = Open3.capture3(
            "ace-context", preset, "--output", "stdio"
          )

          if status.success?
            # Extract just the content part, skip metadata
            if stdout =~ /## Files\n\n(.*)/m
              $1 || stdout
            else
              stdout
            end
          else
            debug_log("Failed to load ace-context: #{stderr}")
            "<!-- Project context unavailable -->"
          end
        rescue => e
          debug_log("Error loading ace-context: #{e.message}")
          "<!-- Project context unavailable -->"
        end

        def call_llm_query(prompt, system_prompt, context)
          # Save system prompt to temp file (llm-query needs file path)
          Tempfile.create(['idea_system', '.md']) do |f|
            f.write(system_prompt)
            f.flush

            # Get model from config or use default
            model = context[:llm_model] || @config.dig("defaults", "llm_model") || "gflash"

            debug_log("Calling llm-query with model: #{model}")

            stdout, stderr, status = Open3.capture3(
              "llm-query",
              model,
              prompt,
              "--system", f.path,
              "--format", "json"
            )

            if status.success?
              begin
                # llm-query returns JSON with a 'text' field containing our response
                wrapper = JSON.parse(stdout)

                # Extract the actual response from the text field
                if wrapper["text"]
                  text = wrapper["text"].strip

                  # Strip markdown code blocks if present (fallback for older prompts)
                  if text.start_with?("```json") && text.end_with?("```")
                    debug_log("Stripping markdown json code blocks from response")
                    text = text.gsub(/^```json\s*\n?/, '').gsub(/\n?```\s*$/, '')
                  elsif text.start_with?("```") && text.end_with?("```")
                    debug_log("Stripping markdown code blocks from response")
                    text = text.gsub(/^```\s*\n?/, '').gsub(/\n?```\s*$/, '')
                  end

                  # Parse the cleaned JSON
                  data = JSON.parse(text)
                  debug_log("Successfully parsed LLM response")
                  { success: true, data: data }
                else
                  debug_log("No text field in LLM response: #{stdout}")
                  { success: false, error: "Invalid response format from llm-query" }
                end
              rescue JSON::ParserError => e
                debug_log("Invalid JSON response: #{stdout[0..500]}...")
                { success: false, error: "Invalid JSON response: #{e.message}" }
              end
            else
              { success: false, error: stderr }
            end
          end
        end

        def format_enhanced_idea(llm_data, original_content, context)
          enhanced = []

          # Add YAML frontmatter with metadata
          enhanced << "---"
          enhanced << "title: #{llm_data['title']}" if llm_data['title']
          enhanced << "filename_suggestion: #{llm_data['filename']}" if llm_data['filename']
          enhanced << "enhanced_at: #{Time.now.strftime('%Y-%m-%d %H:%M:%S')}"
          enhanced << "location: #{context[:location]}" if context[:location]
          enhanced << "llm_model: #{context[:llm_model] || @config.dig('defaults', 'llm_model') || 'gflash'}"
          enhanced << "---"
          enhanced << ""

          # Add enhanced description
          enhanced << llm_data['enhanced_description'] if llm_data['enhanced_description']
          enhanced << ""
          enhanced << "---"
          enhanced << ""
          enhanced << "## Original Idea"
          enhanced << ""
          enhanced << "```"
          enhanced << original_content.strip
          enhanced << "```"

          content = enhanced.join("\n")

          {
            success: true,
            content: content,
            filename: llm_data['filename'],
            title: llm_data['title']
          }
        end

        def llm_available?
          system("which llm-query > /dev/null 2>&1")
        end

        def gem_root
          # Navigate up from lib/ace/taskflow/molecules to gem root
          File.expand_path("../../../..", __dir__)
        end

        def default_system_prompt
          <<~PROMPT
            You are an AI assistant that enhances raw ideas for a development project.

            Given a raw idea, provide a JSON response with:
            - filename: suggested filename (lowercase, hyphenated)
            - title: clear title for the idea
            - enhanced_description: expanded description with problem, solution, and benefits

            Keep the enhancement concise and actionable.
          PROMPT
        end
      end
    end
  end
end
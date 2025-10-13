# LLM Query Integration for Intelligent Diff Summaries

## Description

Implement focused integration with ace-llm-query specifically for the diff command to provide intelligent change summarization. This feature would analyze git diffs and produce concise, relevant summaries tailored to each document's purpose and focus areas.

## Motivation

Raw git diffs contain all changes but lack context about:
- Which changes are relevant to specific documents
- Why certain changes matter for documentation
- What the actual impact of changes might be
- Which changes can be safely ignored

Intelligent summarization would transform verbose diffs into actionable insights, saving time and improving documentation quality.

## Proposed Implementation

### Core Components

```ruby
# lib/ace/docs/molecules/diff_summarizer.rb
module Ace
  module Docs
    module Molecules
      class DiffSummarizer
        def initialize
          @llm_client = setup_llm_client
        end

        def summarize(diff_content, document, options = {})
          prompt = build_prompt(diff_content, document, options)

          response = @llm_client.query(
            prompt: prompt,
            model: options[:model] || 'default',
            temperature: 0.3  # Low temperature for consistency
          )

          parse_llm_response(response)
        end

        private

        def setup_llm_client
          # Use ace-llm-query via shell command or Ruby integration
          LLMQueryClient.new
        end

        def build_prompt(diff, doc, options)
          DiffPromptBuilder.new.build(
            diff_content: diff,
            document_purpose: doc.purpose,
            document_type: doc.doc_type,
            focus_hints: doc.focus_hints,
            options: options
          )
        end
      end
    end
  end
end
```

### Prompt Engineering

```ruby
# lib/ace/docs/prompts/diff_prompt_builder.rb
class DiffPromptBuilder
  def build(params)
    <<~PROMPT
      You are analyzing code changes to determine their relevance to documentation.

      Document Information:
      - Type: #{params[:document_type]}
      - Purpose: #{params[:document_purpose]}
      - Focus Areas: #{format_focus_hints(params[:focus_hints])}

      Git Diff to Analyze:
      ```diff
      #{params[:diff_content]}
      ```

      Tasks:
      1. Identify changes that affect this document
      2. Explain why each change is relevant
      3. Suggest specific documentation updates needed
      4. Rate relevance (0-100) for each change
      5. Provide an executive summary

      Output Format:
      ```json
      {
        "summary": "Brief overview of relevant changes",
        "relevant_changes": [
          {
            "file": "path/to/file",
            "change_type": "modified|added|deleted",
            "description": "What changed",
            "relevance_score": 85,
            "reason": "Why it matters for this document",
            "suggested_update": "What to update in the documentation"
          }
        ],
        "ignored_changes": {
          "count": 15,
          "reason": "Changes to test files not relevant to architecture docs"
        },
        "update_priority": "high|medium|low",
        "estimated_effort": "minutes|hours"
      }
      ```
    PROMPT
  end

  private

  def format_focus_hints(hints)
    return "None specified" if hints.nil? || hints.empty?

    hints.map do |key, value|
      "- #{key}: #{value}"
    end.join("\n")
  end
end
```

### Integration with Diff Command

```ruby
# Enhanced diff command implementation
class DiffCommand
  def execute_with_llm
    # Get raw diff
    raw_diff = ChangeDetector.get_diff_for_document(document, options)

    # Skip LLM if no changes
    return no_changes_result if raw_diff[:diff].empty?

    # Optionally use LLM for summarization
    if options[:summarize] || options[:intelligent]
      summary = DiffSummarizer.new.summarize(
        raw_diff[:diff],
        document,
        summarize_options
      )

      enhance_diff_with_summary(raw_diff, summary)
    else
      raw_diff
    end
  end

  private

  def enhance_diff_with_summary(diff, summary)
    diff.merge(
      llm_summary: summary[:summary],
      relevant_changes: summary[:relevant_changes],
      update_priority: summary[:update_priority],
      suggested_actions: build_action_list(summary)
    )
  end
end
```

### Caching Strategy

```ruby
# lib/ace/docs/molecules/llm_cache.rb
class LLMCache
  def initialize
    @cache_dir = ".cache/ace-docs/llm"
    FileUtils.mkdir_p(@cache_dir)
  end

  def get(cache_key)
    cache_file = cache_path(cache_key)
    return nil unless File.exist?(cache_file)

    cache_data = JSON.parse(File.read(cache_file))
    return nil if expired?(cache_data)

    cache_data["result"]
  end

  def set(cache_key, result, ttl = 86400)
    cache_file = cache_path(cache_key)

    File.write(cache_file, JSON.pretty_generate({
      key: cache_key,
      result: result,
      created_at: Time.now.to_i,
      ttl: ttl
    }))
  end

  private

  def cache_key_for(diff, document)
    Digest::SHA256.hexdigest("#{diff}:#{document.path}:#{document.last_updated}")
  end
end
```

### Output Formats

1. **Concise Summary Mode**
   ```
   Changes Summary for docs/architecture.md:

   HIGH PRIORITY:
   - New ace-docs component added to system
     → Update component list and integration section

   MEDIUM PRIORITY:
   - Modified error handling in ace-core
     → Consider updating error handling guidelines

   IGNORED: 45 changes to test files and documentation
   ```

2. **Detailed Analysis Mode**
   ```json
   {
     "document": "docs/architecture.md",
     "analysis_date": "2025-10-13",
     "total_changes": 52,
     "relevant_changes": 7,
     "recommendations": [
       {
         "section": "Component Architecture",
         "action": "Add ace-docs to component list",
         "reason": "New gem added to ecosystem"
       }
     ]
   }
   ```

3. **Interactive Mode**
   ```
   Analyzing changes for docs/tools.md...

   Found 3 highly relevant changes:

   1. ace-docs CLI added (relevance: 95%)
      Suggestion: Add ace-docs commands to tools table
      [Accept/Skip/Details]?
   ```

### Configuration Options

```yaml
# .ace/docs/config.yml
llm:
  diff_summaries:
    enabled: true
    model: gpt-4            # Model for analysis
    temperature: 0.3        # Lower = more deterministic

    thresholds:
      high_relevance: 80    # Score for high priority
      medium_relevance: 50  # Score for medium priority
      ignore_below: 30      # Ignore changes below this

    output:
      format: concise       # concise|detailed|json
      save_analysis: true   # Save to cache

    focus:
      prioritize:
        - breaking_changes
        - api_changes
        - new_features
      ignore:
        - test_files
        - vendor_code
        - generated_files
```

### Command-Line Interface

```bash
# Basic intelligent diff
ace-docs diff --intelligent

# Specific summarization options
ace-docs diff --summarize --model gpt-4
ace-docs diff --summarize --focus breaking-changes
ace-docs diff --summarize --output json

# Batch analysis
ace-docs diff --all --summarize > analysis.md

# Interactive mode
ace-docs diff --interactive
```

## Benefits

- **Time Saving**: Quickly identify what matters in large diffs
- **Reduced Noise**: Filter out irrelevant changes automatically
- **Better Context**: Understand why changes matter
- **Actionable Insights**: Get specific update recommendations
- **Consistency**: Same analysis criteria applied every time

## Implementation Phases

### Phase 1: Basic Integration
- Wire up ace-llm-query
- Simple prompt template
- Basic relevance scoring

### Phase 2: Enhanced Analysis
- Sophisticated prompts
- Multiple output formats
- Caching implementation

### Phase 3: Interactive Features
- Interactive acceptance mode
- Learning from user feedback
- Custom focus profiles

## Performance Optimization

- **Diff Chunking**: Split large diffs for processing
- **Parallel Processing**: Analyze multiple documents simultaneously
- **Smart Caching**: Cache based on diff hash and document version
- **Incremental Analysis**: Only analyze new changes since last run

## Error Handling

- **LLM Unavailable**: Fall back to basic diff display
- **Rate Limiting**: Queue and retry with backoff
- **Invalid Responses**: Validate JSON structure
- **Context Limits**: Smart truncation of large diffs

## Future Enhancements

- **Learning System**: Improve relevance based on user feedback
- **Custom Prompts**: User-defined prompt templates
- **Webhook Integration**: Trigger on git push events
- **Batch Processing**: Analyze multiple repos/branches
- **Visualization**: Graphical diff relevance maps

## Related Ideas

- Integration with ace-review for code review documentation
- Connection to ace-taskflow for task-based documentation updates
- Coordination with CI/CD for automated documentation checks
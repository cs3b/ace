## Ruby AI Agent SDK Development Standards

### 1. Agent Definition Style

1. **DSL Structure**:
   - One agent definition per file in clear contexts
   - Related agents should be grouped in modules
   - Keep agent definitions focused and minimal

```ruby
# good
agent :web_extractor do
  description "Extract webpage content to markdown"
  input :url
  output :markdown_file
  prompt <<~PROMPT
    Extract content from <%= url %>
  PROMPT
  tools :web_browser
end

# bad - too many responsibilities
agent :do_everything do
  description "Extracts, summarizes and translates content"
  input :url, :language 
  output :translation
  prompt <<~PROMPT
    Extract from <%= url %> 
    Then summarize and translate to <%= language %>
  PROMPT
  tools :web_browser, :translator, :summarizer
end
```

2. **Prompt Style**:
   - Use heredoc (<<~PROMPT) for multi-line prompts
   - Keep ERB interpolation simple and focused
   - Add comments for complex variable interpolation

```ruby
# good
prompt <<~PROMPT
  Given the URL <%= url %>, extract main content.
  Focus on <%= focus_areas.join(", ") %>.
PROMPT

# bad - complex logic in ERB
prompt <<~PROMPT
  <%= if complex_condition?
        "Do complex thing with #{value}"
      else
        "Do simple thing with #{value}"
      end %>
PROMPT
```

### 2. Tool Integration 

1. **Tool Registry Pattern**:
   ```ruby
   # good
   agent :content_processor do
     tools :web_browser, :markdown_converter
   end

   # bad - direct tool instantiation
   agent :content_processor do
     def initialize
       @browser = Browser.new
       @converter = MarkdownConverter.new
     end
   end
   ```

2. **Step Definition**:
   ```ruby
   # good - clear step definitions
   steps do
     step :download, using: :web_browser do |context|
       context[:file] = download_file(context[:url])
     end
     
     step :convert do |context|
       context[:output] = process_file(context[:file])
     end
   end

   # bad - unclear step responsibilities
   steps do
     step :do_stuff do |context|
       # Multiple operations mixed together
       download_and_process(context)
     end
   end
   ```

### 3. Error Handling

1. **Agent-Specific Errors**:
   ```ruby
   module RubyAIAgent
     class AgentError < Error; end
     class PromptError < AgentError; end
     class ToolError < AgentError; end
     class StepError < AgentError; end
   end
   ```

2. **Context Preservation**:
   ```ruby
   # good
   step :process do |context|
     begin
       result = tool.process(context[:input])
       context[:output] = result
     rescue ToolError => e
       raise StepError.new("Failed to process: #{e.message}", 
         step: :process,
         input: context[:input],
         cause: e)
     end
   end
   ```

### 4. Testing Standards

1. **Agent Testing**:
   ```ruby
   RSpec.describe WebExtractor do
     let(:agent) { AgentRegistry.get(:web_extractor) }
     
     it "processes a webpage" do
       context = { url: "http://example.com" }
       expect(agent.render_prompt(context))
         .to include("Extract content from http://example.com")
     end
   end
   ```

2. **Step Testing**:
   ```ruby
   RSpec.describe "YouTube processing steps" do
     it "downloads audio correctly" do
       context = { youtube_url: "http://youtube.com/xyz" }
       step = Step.new(:download_audio, using: :youtube_downloader)
       
       step.run(context)
       expect(context[:audio_file]).to exist
     end
   end
   ```

### 5. File Organization

1. **Agent Definitions**:
```
lib/
  ruby_ai_agent/
    agents/
      web_extractor.rb
      markdown_summarizer.rb
    tools/
      web_browser.rb
      markdown_converter.rb
    steps/
      download_step.rb
      convert_step.rb
```

2. **Supporting Files**:
```
spec/
  agents/
    web_extractor_spec.rb
  tools/
    web_browser_spec.rb
  steps/
    download_step_spec.rb
examples/
  web_extraction.rb
  youtube_processing.rb
```
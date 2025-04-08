## Testing Guidelines

### 1. Testing Strategy

1. **Directory Structure**:
   ```
   spec/
   ├── unit/                    # Unit tests
   │   ├── agents/             
   │   ├── tools/              
   │   └── core/               
   ├── integration/             # Integration tests
   │   ├── agent_tool_spec.rb  
   │   └── llm_agent_spec.rb   
   ├── end_to_end/             # E2E tests
   │   └── workflows/          
   ├── support/                 # Test helpers
   │   ├── agent_helpers.rb    
   │   └── tool_helpers.rb     
   └── spec_helper.rb          # Configuration
   ```

2. **Test Types**:
   ```ruby
   # Unit test example
   RSpec.describe Aira::Agent do
     let(:agent) { described_class.new("test_agent") }
     
     it "validates tool configuration" do
       expect { 
         agent.add_tool(nil) 
       }.to raise_error(ArgumentError)
     end
   end

   # Integration test example
   RSpec.describe "Agent-Tool Integration" do
     let(:agent) { Aira::Agent.new("browser_agent") }
     let(:tool) { Aira::Tools::Browser.new }

     it "executes tools in workflow" do
       agent.add_tool(tool)
       result = agent.execute("Browse website")
       expect(result).to be_successful
     end
   end

   # E2E test example
   RSpec.describe "Web Browsing Workflow" do
     it "completes full browsing task" do
       result = Aira.run_workflow(
         agent: :browser,
         task: "Summarize webpage",
         input: { url: "https://example.com" }
       )
       expect(result.summary).to be_present
     end
   end
   ```

### 2. Thread Safety Testing

1. **Concurrent Operations**:
   ```ruby
   RSpec.describe Aira::ToolRegistry do
     it "handles concurrent tool registration" do
       registry = described_class.new
       tools = Array.new(10) { |i| TestTool.new("tool_#{i}") }
       
       threads = tools.map do |tool|
         Thread.new { registry.register(tool) }
       end
       
       threads.each(&:join)
       expect(registry.count).to eq(10)
     end
   end
   ```

2. **Resource Management**:
   ```ruby
   RSpec.describe Aira::Agent do
     it "cleans up resources after task" do
       agent = described_class.new
       agent.execute_task("test task")
       
       expect(agent.resources).to be_empty
       expect(Thread.list.count).to eq(@initial_thread_count)
     end
   end
   ```

### 3. Test Helpers

1. **Shared Contexts**:
   ```ruby
   # spec/support/shared_contexts.rb
   RSpec.shared_context "with test agent" do
     let(:agent) { Aira::Agent.new("test") }
     let(:tools) { [:browser, :file_system] }
     
     before do
       tools.each { |t| agent.add_tool(t) }
     end
   end
   ```

2. **Custom Matchers**:
   ```ruby
   # spec/support/matchers.rb
   RSpec::Matchers.define :be_successful_result do
     match do |result|
       result.success? && !result.output.nil?
     end
   end
   ```

### 4. Performance Testing

1. **Benchmarking**:
   ```ruby
   require 'benchmark'

   RSpec.describe "Agent Performance" do
     it "completes tasks within time limit" do
       time = Benchmark.realtime do
         agent.execute_complex_task
       end
       expect(time).to be < 5.0 # seconds
     end
   end
   ```

2. **Load Testing**:
   ```ruby
   RSpec.describe "System Load" do
     it "handles multiple concurrent agents" do
       agents = Array.new(50) { Aira::Agent.new }
       
       Benchmark.bm do |bm|
         bm.report("concurrent operation") do
           threads = agents.map do |agent|
             Thread.new { agent.execute_task }
           end
           threads.each(&:join)
         end
       end
     end
   end
   ```

### 5. Test Commands

```bash
# Run entire test suite
bundle exec rspec

# Run specific test file
bundle exec rspec spec/unit/agents/base_spec.rb

# Run specific test
bundle exec rspec spec/unit/agents/base_spec.rb:42

# Run with tags
bundle exec rspec --tag integration

# Generate coverage report
COVERAGE=true bundle exec rspec
```

### 6. Best Practices
### 7. External Service Mocking

1. **Using VCR**:
```ruby
require 'vcr'

VCR.configure do |config|
  config.cassette_library_dir = "spec/fixtures/vcr_cassettes"
  config.hook_into :webmock
  config.filter_sensitive_data('<API_KEY>') { ENV['API_KEY'] }
end

RSpec.describe Aira::LLMClient do
  it "handles API responses" do
    VCR.use_cassette("llm_response") do
      response = client.complete("test prompt")
      expect(response).to be_successful
    end
  end
end
```

2. **Using WebMock**:
```ruby
require 'webmock/rspec'

RSpec.describe Aira::Tools::Browser do
  before do
    stub_request(:get, "https://example.com")
      .to_return(status: 200, body: "Hello World")
  end

  it "fetches web content" do
    result = browser.fetch("https://example.com")
    expect(result.body).to eq("Hello World")
  end
end
```

### 8. Test Data Management

1. **Using Faker**:
```ruby
require 'faker'

RSpec.describe Aira::Agent do
  let(:test_data) do
    {
      name: Faker::Name.name,
      prompt: Faker::Lorem.paragraph,
      context: Faker::Json.shallow_json
    }
  end
end
```

2. **Fixtures**:
```ruby
# spec/fixtures/prompts.yml
chat_prompt:
  role: user
  content: "Test prompt"
  
system_prompt:
  role: system
  content: "You are a helpful assistant"
```

### 9. Load Testing

```ruby
require 'benchmark'

RSpec.describe "Performance" do
  it "handles concurrent requests" do
    agents = Array.new(100) { Aira::Agent.new }
    
    Benchmark.bm do |bm|
      bm.report("parallel execution") do
        results = Parallel.map(agents, in_threads: 10) do |agent|
          agent.execute("test task")
        end
        expect(results).to all(be_successful)
      end
    end
  end
end
```

1. **Test Organization**:
   - One test file per class/module
   - Descriptive context/describe blocks
   - Clear test names

2. **Test Quality**:
   - Test edge cases
   - Verify error conditions
   - Check thread safety
   - Monitor performance

3. **Test Maintenance**:
   - Keep tests focused
   - Use shared examples
   - Maintain test data
   - Update with features
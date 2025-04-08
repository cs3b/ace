## Testing Framework Setup

### 1. RSpec Configuration

```ruby
# spec/spec_helper.rb
require 'rspec'
require 'faker'
require 'vcr'
require 'webmock/rspec'

RSpec.configure do |config|
  config.before(:suite) do
    # Setup test environment
    RubyAIAgent.env = :test
  end
  
  config.around(:each) do |example|
    # Clear any cached data
    RubyAIAgent.reset!
    example.run
  end
end

# Mock external services
VCR.configure do |config|
  config.cassette_library_dir = "spec/fixtures/vcr_cassettes"
  config.hook_into :webmock
  config.configure_rspec_metadata!
  
  # Filter sensitive data
  config.filter_sensitive_data('<API_KEY>') { ENV['API_KEY'] }
end
```

### 2. Test Data Management

```ruby
# spec/factories/prompts.rb
FactoryBot.define do
  factory :prompt, class: Hash do
    content { Faker::Lorem.paragraph }
    temperature { rand(0.0..1.0) }
    
    trait :with_context do
      context { { role: "user", history: [] } }
    end
    
    initialize_with { attributes }
  end
end

# spec/fixtures/test_data.yml
prompts:
  basic:
    content: "What is 2+2?"
    temperature: 0.7
  complex:
    content: "Analyze this code..."
    temperature: 0.9
    max_tokens: 1000
```

### 3. Integration Testing

```ruby
RSpec.describe "Agent Integration", :integration do
  let(:agent) { RubyAIAgent::Agent.new }
  let(:tool) { RubyAIAgent::Tools::Calculator.new }
  
  around(:each) do |example|
    VCR.use_cassette("integration_#{example.description}") do
      example.run
    end
  end
  
  it "executes complete workflow" do
    agent.add_tool(tool)
    result = agent.execute(
      prompt: build(:prompt, :with_context),
      max_retries: 2
    )
    
    expect(result).to be_successful
    expect(result.output).to include("calculation result")
  end
end
```

### 4. Performance Testing

```ruby
RSpec.describe "Performance", :performance do
  include PerformanceHelpers
  
  it "handles concurrent requests within threshold" do
    measure_concurrent_execution(threads: 10) do |stats|
      expect(stats.average_response_time).to be < 1.0
      expect(stats.error_rate).to be < 0.01
    end
  end
  
  it "manages memory usage" do
    measure_memory_usage do |stats|
      expect(stats.peak_memory_mb).to be < 200
      expect(stats.memory_growth_mb).to be < 10
    end
  end
end
```
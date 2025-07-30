# Example XML Prompts for Different Focus Areas

## Code Review Example

```yaml
---
generated: 2024-07-03T12:00:00Z
target: example.rb
focus: code
context: auto
type: review-prompt
---

<review-prompt>
  <project-context>
    <document type="blueprint">
      <![CDATA[
# Project Structure
This Ruby gem follows ATOM architecture...
      ]]>
    </document>
    <document type="vision">
      <![CDATA[
# Project Vision
We build development automation tools...
      ]]>
    </document>
  </project-context>

  <review-target type="file">
    <![CDATA[
class ExampleService
  def initialize(config)
    @config = config
  end
  
  def process(data)
    validate_data(data)
    transform_data(data)
  end
end
    ]]>
  </review-target>

  <focus-areas type="code">
    <area>Code quality, architecture, security, performance</area>
    <area>ATOM architecture compliance</area>
    <area>Ruby best practices and conventions</area>
  </focus-areas>
</review-prompt>
```

## Tests Review Example

```yaml
---
generated: 2024-07-03T12:00:00Z
target: example_spec.rb
focus: tests
context: auto
type: review-prompt
---

<review-prompt>
  <project-context>
    <document type="blueprint">
      <![CDATA[
# Testing Standards
We use RSpec with specific patterns...
      ]]>
    </document>
  </project-context>

  <review-target type="file">
    <![CDATA[
require 'spec_helper'

RSpec.describe ExampleService do
  let(:config) { { setting: 'value' } }
  subject { described_class.new(config) }
  
  describe '#process' do
    it 'processes data correctly' do
      expect(subject.process('data')).to be_truthy
    end
  end
end
    ]]>
  </review-target>

  <focus-areas type="tests">
    <area>Test coverage, quality, maintainability</area>
    <area>RSpec best practices</area>
    <area>Test architecture and organization</area>
  </focus-areas>
</review-prompt>
```

## Documentation Review Example

```yaml
---
generated: 2024-07-03T12:00:00Z
target: README.md
focus: docs
context: auto
type: review-prompt
---

<review-prompt>
  <project-context>
    <document type="blueprint">
      <![CDATA[
# Documentation Standards
All documentation follows these patterns...
      ]]>
    </document>
  </project-context>

  <review-target type="file">
    <![CDATA[
# Example Project

This project provides automation tools for development workflows.

## Installation

Add this line to your Gemfile:

```ruby
gem 'example-project'
```

## Usage

Basic usage example:

```ruby
service = ExampleService.new(config)
result = service.process(data)
```

    ]]>
  </review-target>

  <focus-areas type="docs">
    <area>Documentation gaps, updates, cross-references</area>
    <area>Architecture documentation alignment</area>
    <area>User experience and clarity</area>
  </focus-areas>
</review-prompt>
```

## Benefits of XML Structure

1. **Semantic meaning**: Clear content sections with purpose
2. **Complete preservation**: CDATA sections protect original formatting
3. **Type safety**: Attributes indicate content types
4. **LLM friendly**: Structured data easier to parse and understand
5. **Extensible**: Can add new document types and areas as needed

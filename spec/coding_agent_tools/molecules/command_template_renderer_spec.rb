# frozen_string_literal: true

require 'spec_helper'
require 'coding_agent_tools/molecules/command_template_renderer'

RSpec.describe CodingAgentTools::Molecules::CommandTemplateRenderer do
  let(:renderer) { described_class.new }

  describe '#render' do
    it 'renders default template for unknown workflow' do
      content = renderer.render('unknown-workflow', 'unknown-workflow.wf.md')
      
      expect(content).to include('@dev-handbook/workflow-instructions/unknown-workflow.wf.md')
      expect(content).to include('@.claude/commands/commit.md')
    end
    
    it 'renders custom template for commit workflow' do
      content = renderer.render('commit')
      
      expect(content).to include('@dev-handbook/workflow-instructions/commit.wf.md')
      expect(content).to include('Follow the instructions exactly')
    end
    
    it 'renders custom template for load-project-context workflow' do
      content = renderer.render('load-project-context')
      
      expect(content).to include('@dev-handbook/workflow-instructions/load-project-context.wf.md')
      expect(content).to include('Load all the context documents')
    end
    
    it 'uses provided custom template' do
      custom = 'Custom template content'
      content = renderer.render('any', nil, custom_template: custom)
      
      expect(content).to eq(custom)
    end
  end
  
  describe '#render_with_variables' do
    it 'substitutes variables in template' do
      template = 'Hello %{name}, welcome to %{place}!'
      result = renderer.render_with_variables(template, name: 'Alice', place: 'Wonderland')
      
      expect(result).to eq('Hello Alice, welcome to Wonderland!')
    end
    
    it 'handles missing variables gracefully' do
      template = 'Hello %{name}!'
      result = renderer.render_with_variables(template)
      
      expect(result).to eq('Hello %{name}!')
    end
  end
  
  describe '#available_custom_templates' do
    it 'returns list of workflows with custom templates' do
      templates = renderer.available_custom_templates
      
      expect(templates).to include('commit')
      expect(templates).to include('load-project-context')
    end
  end
  
  describe '#has_custom_template?' do
    it 'returns true for workflows with custom templates' do
      expect(renderer.has_custom_template?('commit')).to be true
      expect(renderer.has_custom_template?('load-project-context')).to be true
    end
    
    it 'returns false for workflows without custom templates' do
      expect(renderer.has_custom_template?('unknown')).to be false
    end
  end
  
  describe '#validate_template' do
    it 'validates template with placeholders' do
      template = "Read @dev-handbook/workflow-instructions/%{filename}\n\nFollow the instructions in the file."
      result = renderer.validate_template(template)
      
      expect(result[:valid]).to be true
      expect(result[:placeholders]).to eq(['filename'])
      expect(result[:warnings]).to be_empty
    end
    
    it 'warns about missing @ references' do
      template = 'Just some text'
      result = renderer.validate_template(template)
      
      expect(result[:valid]).to be true
      expect(result[:warnings]).to include('Template contains no @ references to files')
    end
    
    it 'warns about very short templates' do
      template = 'Short'
      result = renderer.validate_template(template)
      
      expect(result[:valid]).to be true
      expect(result[:warnings]).to include('Template is very short, consider adding more guidance')
    end
  end
end
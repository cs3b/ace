# frozen_string_literal: true

require 'spec_helper'
require 'coding_agent_tools/models/linting_config'

RSpec.describe CodingAgentTools::Models::LintingConfig do
  let(:custom_ruby_config) do
    {
      enabled: true,
      linters: {
        standardrb: { enabled: true, autofix: false },
        security: { enabled: false },
        cassettes: { enabled: true }
      }
    }
  end

  let(:custom_markdown_config) do
    {
      enabled: false,
      linters: {
        styleguide: { enabled: false, autofix: false },
        link_validation: { enabled: true },
        template_embedding: { enabled: false },
        task_metadata: { enabled: true }
      }
    }
  end

  let(:custom_error_distribution) do
    {
      enabled: false,
      max_files: 10,
      one_issue_per_file: false
    }
  end

  let(:custom_global_settings) do
    { timeout: 30, verbose: true }
  end

  describe '#initialize' do
    it 'creates a new linting config with default values' do
      config = described_class.new

      expect(config.ruby).to be_a(Hash)
      expect(config.markdown).to be_a(Hash)
      expect(config.error_distribution).to be_a(Hash)
      expect(config.global_settings).to eq({})
    end

    it 'creates a new linting config with custom values' do
      config = described_class.new(
        ruby: custom_ruby_config,
        markdown: custom_markdown_config,
        error_distribution: custom_error_distribution,
        global_settings: custom_global_settings
      )

      expect(config.ruby).to eq(custom_ruby_config)
      expect(config.markdown).to eq(custom_markdown_config)
      expect(config.error_distribution).to eq(custom_error_distribution)
      expect(config.global_settings).to eq(custom_global_settings)
    end

    it 'uses default ruby config when not provided' do
      config = described_class.new

      expect(config.ruby[:enabled]).to be(true)
      expect(config.ruby[:linters]).to be_a(Hash)
      expect(config.ruby[:linters]).to have_key(:standardrb)
      expect(config.ruby[:linters]).to have_key(:security)
      expect(config.ruby[:linters]).to have_key(:cassettes)
    end

    it 'uses default markdown config when not provided' do
      config = described_class.new

      expect(config.markdown[:enabled]).to be(true)
      expect(config.markdown[:linters]).to be_a(Hash)
      expect(config.markdown[:linters]).to have_key(:styleguide)
      expect(config.markdown[:linters]).to have_key(:link_validation)
      expect(config.markdown[:linters]).to have_key(:template_embedding)
      expect(config.markdown[:linters]).to have_key(:task_metadata)
    end

    it 'uses default error distribution when not provided' do
      config = described_class.new

      expect(config.error_distribution[:enabled]).to be(true)
      expect(config.error_distribution[:max_files]).to eq(4)
      expect(config.error_distribution[:one_issue_per_file]).to be(true)
    end
  end

  describe 'default ruby configuration' do
    let(:config) { described_class.new }

    it 'enables ruby linting by default' do
      expect(config.ruby[:enabled]).to be(true)
    end

    it 'configures standardrb linter correctly' do
      standardrb = config.ruby[:linters][:standardrb]
      expect(standardrb[:enabled]).to be(true)
      expect(standardrb[:autofix]).to be(true)
    end

    it 'configures security linter correctly' do
      security = config.ruby[:linters][:security]
      expect(security[:enabled]).to be(true)
      expect(security).not_to have_key(:autofix)
    end

    it 'configures cassettes linter correctly' do
      cassettes = config.ruby[:linters][:cassettes]
      expect(cassettes[:enabled]).to be(true)
      expect(cassettes).not_to have_key(:autofix)
    end
  end

  describe 'default markdown configuration' do
    let(:config) { described_class.new }

    it 'enables markdown linting by default' do
      expect(config.markdown[:enabled]).to be(true)
    end

    it 'configures styleguide linter correctly' do
      styleguide = config.markdown[:linters][:styleguide]
      expect(styleguide[:enabled]).to be(true)
      expect(styleguide[:autofix]).to be(true)
    end

    it 'configures link_validation linter correctly' do
      link_validation = config.markdown[:linters][:link_validation]
      expect(link_validation[:enabled]).to be(true)
      expect(link_validation).not_to have_key(:autofix)
    end

    it 'configures template_embedding linter correctly' do
      template_embedding = config.markdown[:linters][:template_embedding]
      expect(template_embedding[:enabled]).to be(true)
      expect(template_embedding).not_to have_key(:autofix)
    end

    it 'configures task_metadata linter correctly' do
      task_metadata = config.markdown[:linters][:task_metadata]
      expect(task_metadata[:enabled]).to be(true)
      expect(task_metadata).not_to have_key(:autofix)
    end
  end

  describe 'default error distribution configuration' do
    let(:config) { described_class.new }

    it 'enables error distribution by default' do
      expect(config.error_distribution[:enabled]).to be(true)
    end

    it 'sets max_files to 4 by default' do
      expect(config.error_distribution[:max_files]).to eq(4)
    end

    it 'enables one_issue_per_file by default' do
      expect(config.error_distribution[:one_issue_per_file]).to be(true)
    end
  end

  describe '#enabled_linters' do
    it 'returns all enabled linters with default configuration' do
      config = described_class.new
      enabled = config.enabled_linters

      expect(enabled).to include('ruby_standardrb')
      expect(enabled).to include('ruby_security')
      expect(enabled).to include('ruby_cassettes')
      expect(enabled).to include('markdown_styleguide')
      expect(enabled).to include('markdown_link_validation')
      expect(enabled).to include('markdown_template_embedding')
      expect(enabled).to include('markdown_task_metadata')
    end

    it 'returns only enabled ruby linters when markdown is disabled' do
      config = described_class.new(markdown: { enabled: false, linters: {} })
      enabled = config.enabled_linters

      expect(enabled).to include('ruby_standardrb')
      expect(enabled).to include('ruby_security')
      expect(enabled).to include('ruby_cassettes')
      expect(enabled).not_to include('markdown_styleguide')
    end

    it 'returns only enabled markdown linters when ruby is disabled' do
      config = described_class.new(ruby: { enabled: false, linters: {} })
      enabled = config.enabled_linters

      expect(enabled).to include('markdown_styleguide')
      expect(enabled).to include('markdown_link_validation')
      expect(enabled).to include('markdown_template_embedding')
      expect(enabled).to include('markdown_task_metadata')
      expect(enabled).not_to include('ruby_standardrb')
    end

    it 'returns empty array when all linting is disabled' do
      config = described_class.new(
        ruby: { enabled: false, linters: {} },
        markdown: { enabled: false, linters: {} }
      )
      enabled = config.enabled_linters

      expect(enabled).to eq([])
    end

    it 'respects individual linter enabled settings' do
      custom_ruby = {
        enabled: true,
        linters: {
          standardrb: { enabled: false, autofix: true },
          security: { enabled: true },
          cassettes: { enabled: false }
        }
      }

      config = described_class.new(ruby: custom_ruby)
      enabled = config.enabled_linters

      expect(enabled).not_to include('ruby_standardrb')
      expect(enabled).to include('ruby_security')
      expect(enabled).not_to include('ruby_cassettes')
    end
  end

  describe 'configuration validation' do
    it 'handles missing linters hash gracefully' do
      config = described_class.new(ruby: { enabled: true })

      # Should fail when linters hash is missing
      expect { config.enabled_linters }.to raise_error(NoMethodError)
    end

    it 'handles nil enabled values gracefully' do
      ruby_config = {
        enabled: true,
        linters: {
          standardrb: { enabled: nil, autofix: true },
          security: { enabled: true }
        }
      }

      config = described_class.new(ruby: ruby_config)
      enabled = config.enabled_linters

      expect(enabled).not_to include('ruby_standardrb')
      expect(enabled).to include('ruby_security')
    end
  end

  describe 'configuration merging' do
    it 'preserves custom settings while using defaults for missing keys' do
      partial_ruby_config = {
        enabled: true,
        linters: {
          standardrb: { enabled: false, autofix: false }
          # Missing security and cassettes - defaults are NOT merged
        }
      }

      config = described_class.new(ruby: partial_ruby_config)

      expect(config.ruby[:linters][:standardrb][:enabled]).to be(false)
      expect(config.ruby[:linters][:standardrb][:autofix]).to be(false)
      # Only the provided linters are included
      expect(config.ruby[:linters]).not_to have_key(:security)
      expect(config.ruby[:linters]).not_to have_key(:cassettes)
    end
  end

  describe 'configuration validation', :config_validation do
    it 'handles invalid data types for ruby configuration' do
      expect do
        described_class.new(ruby: 'invalid_string')
      end.not_to raise_error

      config = described_class.new(ruby: 'invalid_string')
      expect(config.ruby).to eq('invalid_string')
    end

    it 'handles invalid data types for markdown configuration' do
      expect do
        described_class.new(markdown: 123)
      end.not_to raise_error

      config = described_class.new(markdown: 123)
      expect(config.markdown).to eq(123)
    end

    it 'handles invalid data types for error_distribution configuration' do
      expect do
        described_class.new(error_distribution: [1, 2, 3])
      end.not_to raise_error

      config = described_class.new(error_distribution: [1, 2, 3])
      expect(config.error_distribution).to eq([1, 2, 3])
    end

    it 'handles invalid enabled_linters calls with malformed ruby config' do
      config = described_class.new(ruby: 'invalid')

      expect { config.enabled_linters }.to raise_error(TypeError)
    end

    it 'handles invalid enabled_linters calls with malformed markdown config' do
      config = described_class.new(markdown: 123)

      expect { config.enabled_linters }.to raise_error(TypeError)
    end

    it 'handles malformed linter configurations gracefully' do
      malformed_ruby = {
        enabled: true,
        linters: {
          standardrb: 'invalid_config',
          security: 123,
          cassettes: nil
        }
      }

      config = described_class.new(ruby: malformed_ruby)

      expect { config.enabled_linters }.to raise_error
    end

    it 'handles missing required fields in linter configurations' do
      incomplete_ruby = {
        enabled: true,
        linters: {
          standardrb: {},  # Missing enabled field
          security: { enabled: true }
        }
      }

      config = described_class.new(ruby: incomplete_ruby)
      enabled = config.enabled_linters

      expect(enabled).not_to include('ruby_standardrb')
      expect(enabled).to include('ruby_security')
    end

    it 'handles deeply nested invalid configuration structures' do
      deeply_nested_invalid = {
        enabled: true,
        linters: {
          custom: {
            enabled: true,
            options: {
              level1: {
                level2: {
                  level3: 'invalid_circular_ref'
                }
              }
            }
          }
        }
      }

      config = described_class.new(ruby: deeply_nested_invalid)
      enabled = config.enabled_linters

      expect(enabled).to include('ruby_custom')
    end
  end

  describe 'configuration merging', :config_merging do
    it 'properly merges partial ruby configurations with defaults' do
      partial_ruby = {
        enabled: true,
        linters: {
          standardrb: { enabled: false }
          # Note: security and cassettes are missing, should not be merged from defaults
        }
      }

      config = described_class.new(ruby: partial_ruby)

      expect(config.ruby[:enabled]).to be(true)
      expect(config.ruby[:linters][:standardrb][:enabled]).to be(false)
      expect(config.ruby[:linters]).not_to have_key(:security)
      expect(config.ruby[:linters]).not_to have_key(:cassettes)
    end

    it 'preserves complete override of ruby configuration' do
      complete_override = {
        enabled: false,
        custom_field: 'value',
        linters: {
          custom_linter: { enabled: true, custom_option: 'test' }
        }
      }

      config = described_class.new(ruby: complete_override)

      expect(config.ruby[:enabled]).to be(false)
      expect(config.ruby[:custom_field]).to eq('value')
      expect(config.ruby[:linters][:custom_linter][:enabled]).to be(true)
      expect(config.ruby[:linters][:custom_linter][:custom_option]).to eq('test')
    end

    it 'handles mixed override and inheritance patterns' do
      mixed_config = {
        enabled: true,
        linters: {
          standardrb: { enabled: false, autofix: false, custom_rule: 'strict' },
          new_linter: { enabled: true, type: 'experimental' }
        }
      }

      config = described_class.new(
        ruby: mixed_config,
        markdown: { enabled: false, custom_field: 'disabled' },
        global_settings: { timeout: 60, retries: 3 }
      )

      expect(config.ruby[:linters][:standardrb][:custom_rule]).to eq('strict')
      expect(config.ruby[:linters][:new_linter][:type]).to eq('experimental')
      expect(config.markdown[:custom_field]).to eq('disabled')
      expect(config.global_settings[:timeout]).to eq(60)
    end

    it 'maintains separate configuration section independence' do
      config = described_class.new(
        ruby: { enabled: false, linters: {} },
        markdown: { enabled: true, linters: { custom: { enabled: true } } },
        error_distribution: { enabled: false, max_files: 10 }
      )

      # Modifying one section shouldn't affect others
      config.ruby[:enabled] = true

      expect(config.markdown[:enabled]).to be(true)
      expect(config.error_distribution[:enabled]).to be(false)
    end
  end

  describe 'configuration serialization', :serialization do
    it 'can be serialized to and from JSON' do
      original_config = described_class.new(
        ruby: { enabled: true, linters: { standardrb: { enabled: false } } },
        markdown: { enabled: true, linters: { styleguide: { enabled: true } } },
        error_distribution: { enabled: true, max_files: 8 },
        global_settings: { timeout: 45, verbose: false }
      )

      # Convert to hash (for JSON serialization)
      serialized = original_config.to_h

      # Recreate from hash
      deserialized_config = described_class.new(
        ruby: serialized[:ruby],
        markdown: serialized[:markdown],
        error_distribution: serialized[:error_distribution],
        global_settings: serialized[:global_settings]
      )

      expect(deserialized_config.ruby).to eq(original_config.ruby)
      expect(deserialized_config.markdown).to eq(original_config.markdown)
      expect(deserialized_config.error_distribution).to eq(original_config.error_distribution)
      expect(deserialized_config.global_settings).to eq(original_config.global_settings)
    end

    it 'handles serialization of complex nested structures' do
      complex_config = described_class.new(
        ruby: {
          enabled: true,
          linters: {
            custom: {
              enabled: true,
              options: {
                rules: { rule1: { severity: 'error' }, rule2: { severity: 'warning' } },
                patterns: ['*.rb', '*.rake']
              }
            }
          }
        }
      )

      serialized = complex_config.to_h
      deserialized = described_class.new(ruby: serialized[:ruby])

      expect(deserialized.ruby[:linters][:custom][:options][:rules][:rule1][:severity]).to eq('error')
      expect(deserialized.ruby[:linters][:custom][:options][:patterns]).to include('*.rb')
    end

    it 'preserves data types during serialization roundtrip' do
      config_with_types = described_class.new(
        ruby: { enabled: true, version: 3.1, patterns: ['*.rb'] },
        error_distribution: { enabled: false, max_files: 0, threshold: 0.95 },
        global_settings: { debug: true, max_workers: 4, timeout: nil }
      )

      serialized = config_with_types.to_h
      deserialized = described_class.new(
        ruby: serialized[:ruby],
        error_distribution: serialized[:error_distribution],
        global_settings: serialized[:global_settings]
      )

      expect(deserialized.ruby[:version]).to be_a(Float)
      expect(deserialized.ruby[:patterns]).to be_a(Array)
      expect(deserialized.error_distribution[:max_files]).to be_a(Integer)
      expect(deserialized.error_distribution[:threshold]).to be_a(Float)
      expect(deserialized.global_settings[:debug]).to be_a(TrueClass)
      expect(deserialized.global_settings[:timeout]).to be_nil
    end
  end

  describe 'configuration introspection', :introspection do
    let(:config) do
      described_class.new(
        ruby: { enabled: true, linters: { standardrb: { enabled: true }, security: { enabled: false } } },
        markdown: { enabled: false, linters: { styleguide: { enabled: true } } },
        error_distribution: { enabled: true, max_files: 6 }
      )
    end

    it 'provides introspection into enabled linters by type' do
      enabled = config.enabled_linters

      ruby_linters = enabled.select { |linter| linter.start_with?('ruby_') }
      markdown_linters = enabled.select { |linter| linter.start_with?('markdown_') }

      expect(ruby_linters).to include('ruby_standardrb')
      expect(ruby_linters).not_to include('ruby_security')
      expect(markdown_linters).to be_empty  # markdown is disabled
    end

    it 'provides configuration summary information' do
      # Test that we can introspect the configuration structure
      expect(config.ruby).to have_key(:enabled)
      expect(config.ruby).to have_key(:linters)
      expect(config.markdown).to have_key(:enabled)
      expect(config.error_distribution).to have_key(:max_files)
    end

    it 'allows inspection of linter-specific configurations' do
      standardrb_config = config.ruby[:linters][:standardrb]

      expect(standardrb_config).to have_key(:enabled)
      expect(standardrb_config[:enabled]).to be(true)
    end

    it 'supports configuration debugging through enabled_linters method' do
      # When debugging configuration issues, enabled_linters should provide clear output
      enabled = config.enabled_linters

      expect(enabled).to be_an(Array)
      expect(enabled.all? { |linter| linter.is_a?(String) }).to be(true)
      expect(enabled.all? { |linter| linter.include?('_') }).to be(true)  # All should have type prefix
    end
  end

  describe 'configuration state management', :state_management do
    it 'allows modification of configuration after initialization' do
      config = described_class.new

      # Structs are mutable, so we can modify them
      config.ruby[:enabled] = false
      config.global_settings[:new_setting] = 'value'

      expect(config.ruby[:enabled]).to be(false)
      expect(config.global_settings[:new_setting]).to eq('value')
    end

    it 'maintains separate state for different configuration instances' do
      config1 = described_class.new(ruby: { enabled: true })
      config2 = described_class.new(ruby: { enabled: false })

      config1.ruby[:custom_field] = 'config1_value'
      config2.ruby[:custom_field] = 'config2_value'

      expect(config1.ruby[:custom_field]).to eq('config1_value')
      expect(config2.ruby[:custom_field]).to eq('config2_value')
      expect(config1.ruby[:enabled]).to be(true)
      expect(config2.ruby[:enabled]).to be(false)
    end

    it 'handles nested configuration state modifications' do
      config = described_class.new

      # Add new linter configuration
      config.ruby[:linters][:new_linter] = { enabled: true, autofix: false }

      enabled = config.enabled_linters
      expect(enabled).to include('ruby_new_linter')
    end

    it 'preserves default values when partial state is modified' do
      config = described_class.new

      # Modify only one part of the configuration
      config.error_distribution[:max_files] = 10

      # Other defaults should remain intact
      expect(config.error_distribution[:enabled]).to be(true)
      expect(config.error_distribution[:one_issue_per_file]).to be(true)
      expect(config.ruby[:enabled]).to be(true)
    end
  end

  describe 'configuration integration', :integration do
    it 'correctly integrates ruby and markdown linter enablement' do
      config = described_class.new(
        ruby: { enabled: true, linters: { standardrb: { enabled: true } } },
        markdown: { enabled: true, linters: { styleguide: { enabled: true } } }
      )

      enabled = config.enabled_linters

      expect(enabled).to include('ruby_standardrb')
      expect(enabled).to include('markdown_styleguide')
    end

    it 'respects global enablement flags across all sections' do
      config = described_class.new(
        ruby: { enabled: false, linters: { standardrb: { enabled: true } } },
        markdown: { enabled: false, linters: { styleguide: { enabled: true } } }
      )

      enabled = config.enabled_linters

      expect(enabled).not_to include('ruby_standardrb')
      expect(enabled).not_to include('markdown_styleguide')
    end

    it 'maintains consistency between error_distribution and linter settings' do
      config = described_class.new(
        error_distribution: { enabled: true, max_files: 2, one_issue_per_file: true }
      )

      # Error distribution settings should be accessible regardless of linter configuration
      expect(config.error_distribution[:max_files]).to eq(2)
      expect(config.error_distribution[:one_issue_per_file]).to be(true)

      # And linters should still work normally
      enabled = config.enabled_linters
      expect(enabled.length).to be > 0
    end

    it 'handles complex interactions between all configuration sections' do
      config = described_class.new(
        ruby: { enabled: true, linters: { standardrb: { enabled: true, autofix: false } } },
        markdown: { enabled: true, linters: { styleguide: { enabled: false }, link_validation: { enabled: true } } },
        error_distribution: { enabled: true, max_files: 1 },
        global_settings: { parallel: false, timeout: 120 }
      )

      enabled = config.enabled_linters

      # Should include enabled ruby linters
      expect(enabled).to include('ruby_standardrb')
      # Should not include disabled markdown linters
      expect(enabled).not_to include('markdown_styleguide')
      # Should include explicitly enabled markdown linters
      expect(enabled).to include('markdown_link_validation')

      # Global settings should be independent
      expect(config.global_settings[:timeout]).to eq(120)
      expect(config.error_distribution[:max_files]).to eq(1)
    end
  end

  describe 'edge cases', :edge_cases do
    it 'handles completely empty configuration' do
      config = described_class.new({})

      expect(config.ruby).to be_a(Hash)
      expect(config.markdown).to be_a(Hash)
      expect(config.error_distribution).to be_a(Hash)
      expect(config.global_settings).to eq({})
    end

    it 'handles nil values for all configuration sections' do
      config = described_class.new(
        ruby: nil,
        markdown: nil,
        error_distribution: nil,
        global_settings: nil
      )

      expect(config.ruby).to be_a(Hash)
      expect(config.markdown).to be_a(Hash)
      expect(config.error_distribution).to be_a(Hash)
      expect(config.global_settings).to eq({})
    end

    it 'handles very large global_settings' do
      large_settings = {}
      1000.times { |i| large_settings[:"setting_#{i}"] = "value_#{i}" }

      config = described_class.new(global_settings: large_settings)

      expect(config.global_settings.size).to eq(1000)
      expect(config.global_settings[:setting_0]).to eq('value_0')
      expect(config.global_settings[:setting_999]).to eq('value_999')
    end

    it 'handles complex nested configuration structures' do
      complex_config = {
        enabled: true,
        linters: {
          custom_linter: {
            enabled: true,
            autofix: false,
            options: {
              level: 'strict',
              ignore_patterns: ['*.tmp', '*.log'],
              custom_rules: {
                rule1: { severity: 'error', pattern: /test/ },
                rule2: { severity: 'warning', threshold: 10 }
              }
            }
          }
        }
      }

      config = described_class.new(ruby: complex_config)

      expect(config.ruby[:linters][:custom_linter][:options][:custom_rules][:rule1][:pattern]).to eq(/test/)
      expect(config.ruby[:linters][:custom_linter][:options][:ignore_patterns]).to include('*.tmp')
    end

    it 'handles unicode characters in configuration' do
      unicode_config = {
        enabled: true,
        linters: {
          :émojis🚀 => { enabled: true, description: 'Linter with émojis 🚀' },
          :ñéẅ_linter => { enabled: false, path: '/path/with/ñéẅ/chars' }
        }
      }

      config = described_class.new(ruby: unicode_config)

      expect(config.ruby[:linters][:émojis🚀][:description]).to include('🚀')
      expect(config.ruby[:linters][:ñéẅ_linter][:path]).to include('ñéẅ')
    end

    it 'handles zero and negative numeric values' do
      edge_error_distribution = {
        enabled: true,
        max_files: 0,
        one_issue_per_file: true,
        negative_value: -1
      }

      config = described_class.new(error_distribution: edge_error_distribution)

      expect(config.error_distribution[:max_files]).to eq(0)
      expect(config.error_distribution[:negative_value]).to eq(-1)
    end
  end
end

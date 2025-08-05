# frozen_string_literal: true

require 'spec_helper'
require 'tempfile'

RSpec.describe CodingAgentTools::Molecules::MethodCoverageMapper do
  subject { described_class.new }

  let(:sample_ruby_content) do
    <<~RUBY
      class TestClass
        def covered_method
          puts "this is covered"
        end

        def uncovered_method
          puts "this is not covered"
          puts "second line not covered"
        end

        def partially_covered_method
          puts "this line is covered"
          puts "this line is not covered"
        end
      end
    RUBY
  end

  let(:sample_lines_data) do
    # Corresponds to the Ruby content above
    [
      nil,  # 0: blank or non-executable
      nil,  # 1: class declaration
      nil,  # 2: def covered_method
      1,    # 3: puts "this is covered" - COVERED
      nil,  # 4: end
      nil,  # 5: blank
      nil,  # 6: def uncovered_method
      0,    # 7: puts "this is not covered" - NOT COVERED
      0,    # 8: puts "second line not covered" - NOT COVERED
      nil,  # 9: end
      nil,  # 10: blank
      nil,  # 11: def partially_covered_method
      1,    # 12: puts "this line is covered" - COVERED
      0,    # 13: puts "this line is not covered" - NOT COVERED
      nil   # 14: end
    ]
  end

  describe '#map_content_coverage' do
    it 'maps methods to their coverage correctly' do
      methods = subject.map_content_coverage(sample_ruby_content, sample_lines_data)

      expect(methods.length).to eq(3)

      covered_method = methods.find { |m| m.name == 'covered_method' }
      expect(covered_method.coverage_percentage).to eq(100.0)
      expect(covered_method.total_lines).to eq(1)
      expect(covered_method.covered_lines).to eq(1)

      uncovered_method = methods.find { |m| m.name == 'uncovered_method' }
      expect(uncovered_method.coverage_percentage).to eq(0.0)
      expect(uncovered_method.total_lines).to eq(2)
      expect(uncovered_method.covered_lines).to eq(0)

      partial_method = methods.find { |m| m.name == 'partially_covered_method' }
      expect(partial_method.coverage_percentage).to eq(50.0)
      expect(partial_method.total_lines).to eq(2)
      expect(partial_method.covered_lines).to eq(1)
    end

    it 'handles empty lines data' do
      methods = subject.map_content_coverage(sample_ruby_content, [])
      expect(methods).to eq([])
    end

    it 'handles nil lines data' do
      methods = subject.map_content_coverage(sample_ruby_content, nil)
      expect(methods).to eq([])
    end

    context 'with parse errors' do
      let(:invalid_ruby) { "class InvalidClass\n  def missing_end" }

      it 'handles parse errors gracefully' do
        expect do
          methods = subject.map_content_coverage(invalid_ruby, sample_lines_data)
          expect(methods).to eq([])
        end.to output(/Warning: Could not parse methods/).to_stderr
      end
    end
  end

  describe '#map_file_coverage' do
    let(:temp_file) { Tempfile.new(['test', '.rb']) }

    before do
      temp_file.write(sample_ruby_content)
      temp_file.rewind
    end

    after { temp_file.unlink }

    it 'maps file coverage correctly' do
      methods = subject.map_file_coverage(temp_file.path, sample_lines_data)

      expect(methods.length).to eq(3)
      expect(methods.map(&:name)).to contain_exactly('covered_method', 'uncovered_method', 'partially_covered_method')
    end

    context 'with non-existent file' do
      it 'handles missing files gracefully' do
        expect do
          methods = subject.map_file_coverage('/non/existent/file.rb', sample_lines_data)
          expect(methods).to eq([])
        end.to output(/Warning: Could not parse methods/).to_stderr
      end
    end
  end

  describe '#filter_under_covered_methods' do
    let(:methods) do
      [
        instance_double(CodingAgentTools::Models::MethodCoverage, under_threshold?: true, name: 'low_coverage'),
        instance_double(CodingAgentTools::Models::MethodCoverage, under_threshold?: false, name: 'high_coverage'),
        instance_double(CodingAgentTools::Models::MethodCoverage, under_threshold?: true, name: 'no_coverage')
      ]
    end

    it 'filters methods below threshold' do
      result = subject.filter_under_covered_methods(methods, 80.0)

      expect(result.length).to eq(2)
      expect(result.map(&:name)).to contain_exactly('low_coverage', 'no_coverage')
    end
  end

  describe '#group_methods_by_coverage' do
    let(:methods) do
      [
        instance_double(CodingAgentTools::Models::MethodCoverage, coverage_percentage: 0.0, name: 'uncovered'),
        instance_double(CodingAgentTools::Models::MethodCoverage, coverage_percentage: 25.0, name: 'low'),
        instance_double(CodingAgentTools::Models::MethodCoverage, coverage_percentage: 65.0, name: 'medium'),
        instance_double(CodingAgentTools::Models::MethodCoverage, coverage_percentage: 90.0, name: 'good')
      ]
    end

    it 'groups methods by coverage levels' do
      result = subject.group_methods_by_coverage(methods)

      expect(result[:uncovered].map(&:name)).to eq(['uncovered'])
      expect(result[:low_coverage].map(&:name)).to eq(['low'])
      expect(result[:medium_coverage].map(&:name)).to eq(['medium'])
      expect(result[:good_coverage].map(&:name)).to eq(['good'])
    end
  end

  describe '#identify_coverage_patterns' do
    let(:methods) do
      [
        instance_double(CodingAgentTools::Models::MethodCoverage,
          coverage_percentage: 0.0, total_lines: 5, name: 'uncovered_method'),
        instance_double(CodingAgentTools::Models::MethodCoverage,
          coverage_percentage: 100.0, total_lines: 3, name: 'perfect_method'),
        instance_double(CodingAgentTools::Models::MethodCoverage,
          coverage_percentage: 50.0, total_lines: 1, name: 'single_line'),
        instance_double(CodingAgentTools::Models::MethodCoverage,
          coverage_percentage: 30.0, total_lines: 15, name: 'large_uncovered')
      ]
    end

    it 'identifies coverage patterns correctly' do
      result = subject.identify_coverage_patterns(methods)

      expect(result[:completely_uncovered].map(&:name)).to eq(['uncovered_method'])
      expect(result[:well_tested].map(&:name)).to eq(['perfect_method'])
      expect(result[:partially_covered].map(&:name)).to contain_exactly('single_line', 'large_uncovered')
      expect(result[:single_line_methods].map(&:name)).to eq(['single_line'])
      expect(result[:large_uncovered_methods].map(&:name)).to eq(['large_uncovered'])
    end
  end

  describe 'integration with real parsing' do
    let(:complex_ruby_content) do
      <<~RUBY
        module TestModule
          class TestClass
            def self.class_method
              "class method"
            end

            def initialize(value)
              @value = value
            end

            private

            def private_method
              @value * 2
            end
          end
        end
      RUBY
    end

    let(:complex_lines_data) do
      [
        nil, nil,  # module, class
        nil, 1, nil,  # self.class_method
        nil, nil, 1, nil,  # initialize
        nil, nil,  # private
        nil, 0, nil,  # private_method
        nil, nil  # end, end
      ]
    end

    it 'handles complex Ruby structures' do
      methods = subject.map_content_coverage(complex_ruby_content, complex_lines_data)

      expect(methods.length).to eq(3)

      class_method = methods.find { |m| m.name == 'self.class_method' }
      expect(class_method).not_to be_nil
      expect(class_method.coverage_percentage).to eq(100.0)

      init_method = methods.find { |m| m.name == 'initialize' }
      expect(init_method).not_to be_nil
      expect(init_method.coverage_percentage).to eq(100.0)

      private_method = methods.find { |m| m.name == 'private_method' }
      expect(private_method).not_to be_nil
      expect(private_method.coverage_percentage).to eq(0.0)
    end
  end
end

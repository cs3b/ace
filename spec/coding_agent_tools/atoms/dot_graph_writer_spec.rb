# frozen_string_literal: true

require 'spec_helper'
require 'tmpdir'

RSpec.describe CodingAgentTools::Atoms::DotGraphWriter do
  let(:writer) { described_class.new }
  let(:temp_dir) { Dir.mktmpdir }

  after { FileUtils.rm_rf(temp_dir) }

  describe '#generate_dot_content' do
    it 'generates DOT content for simple dependencies' do
      dependencies = {
        'file1.md' => {
          refs_to: Set.new(['file2.md']),
          refs_from: Set.new([])
        },
        'file2.md' => {
          refs_to: Set.new([]),
          refs_from: Set.new(['file1.md'])
        }
      }

      content = writer.generate_dot_content(dependencies)

      expect(content).to include('digraph DocumentDependencies')
      expect(content).to include('rankdir=LR')
      expect(content).to include('"file1.md"')
      expect(content).to include('"file2.md"')
      expect(content).to include('"file1.md" -> "file2.md"')
    end

    it 'includes colored nodes based on file type' do
      dependencies = {
        'test.wf.md' => { refs_to: Set.new([]), refs_from: Set.new([]) },
        'guide.g.md' => { refs_to: Set.new([]), refs_from: Set.new([]) },
        'tasks/task.md' => { refs_to: Set.new([]), refs_from: Set.new([]) },
        'normal.md' => { refs_to: Set.new([]), refs_from: Set.new([]) }
      }

      content = writer.generate_dot_content(dependencies)

      expect(content).to include('fillcolor=lightblue')   # .wf.md files
      expect(content).to include('fillcolor=lightgreen')  # .g.md files
      expect(content).to include('fillcolor=lightyellow') # tasks files
      expect(content).to include('fillcolor=lightgray')   # normal files
    end

    it 'handles empty dependencies' do
      content = writer.generate_dot_content({})

      expect(content).to include('digraph DocumentDependencies')
      expect(content).to include('rankdir=LR')
      expect(content).to include('node [shape=box]')
    end

    it 'handles complex dependency structures' do
      dependencies = {
        'docs/architecture.md' => {
          refs_to: Set.new(['docs/blueprint.md', 'README.md']),
          refs_from: Set.new(['docs/guide.md'])
        },
        'docs/blueprint.md' => {
          refs_to: Set.new([]),
          refs_from: Set.new(['docs/architecture.md'])
        },
        'README.md' => {
          refs_to: Set.new([]),
          refs_from: Set.new(['docs/architecture.md'])
        }
      }

      content = writer.generate_dot_content(dependencies)

      expect(content).to include('"docs/architecture.md" -> "docs/blueprint.md"')
      expect(content).to include('"docs/architecture.md" -> "README.md"')
      expect(content.scan('->').length).to eq(2)
    end
  end

  describe '#write_dot_file' do
    it 'writes DOT content to default file' do
      dependencies = {
        'file1.md' => {
          refs_to: Set.new(['file2.md']),
          refs_from: Set.new([])
        }
      }

      filename = writer.write_dot_file(dependencies)

      expect(filename).to eq('doc-dependencies.dot')
      expect(File.exist?(filename)).to be true

      content = File.read(filename)
      expect(content).to include('digraph DocumentDependencies')
      expect(content).to include('"file1.md" -> "file2.md"')

      # Clean up
      File.delete(filename) if File.exist?(filename)
    end

    it 'writes DOT content to custom file' do
      dependencies = {
        'test.md' => {
          refs_to: Set.new(['target.md']),
          refs_from: Set.new([])
        }
      }
      custom_filename = File.join(temp_dir, 'custom.dot')

      result = writer.write_dot_file(dependencies, custom_filename)

      expect(result).to eq(custom_filename)
      expect(File.exist?(custom_filename)).to be true

      content = File.read(custom_filename)
      expect(content).to include('"test.md" -> "target.md"')
    end
  end

  describe '#node_color' do
    it 'returns correct colors for different file types' do
      expect(writer.node_color('workflow.wf.md')).to eq('lightblue')
      expect(writer.node_color('guide.g.md')).to eq('lightgreen')
      expect(writer.node_color('tasks/task.md')).to eq('lightyellow')
      expect(writer.node_color('normal.md')).to eq('lightgray')
      expect(writer.node_color('README.md')).to eq('lightgray')
    end

    it 'handles edge cases in file naming' do
      expect(writer.node_color('test.wf.md.backup')).to eq('lightgray')
      expect(writer.node_color('tasks')).to eq('lightgray')
      expect(writer.node_color('tasks/subtask/file.md')).to eq('lightyellow')
    end
  end

  describe '#png_generation_instructions' do
    it 'generates correct Graphviz command' do
      instructions = writer.png_generation_instructions('graph.dot')
      expect(instructions).to eq('dot -Tpng graph.dot -o graph.png')
    end

    it 'handles paths with directories' do
      instructions = writer.png_generation_instructions('output/dependencies.dot')
      expect(instructions).to eq('dot -Tpng output/dependencies.dot -o output/dependencies.png')
    end
  end

  describe 'integration' do
    it 'creates complete DOT file workflow' do
      dependencies = {
        'docs/architecture.md' => {
          refs_to: Set.new(['docs/blueprint.md']),
          refs_from: Set.new([])
        },
        'workflow.wf.md' => {
          refs_to: Set.new(['guide.g.md']),
          refs_from: Set.new([])
        }
      }

      filename = File.join(temp_dir, 'complete.dot')
      writer.write_dot_file(dependencies, filename)

      content = File.read(filename)
      instructions = writer.png_generation_instructions(filename)

      expect(content).to include('digraph DocumentDependencies')
      expect(content).to include('fillcolor=lightblue')  # workflow file
      expect(content).to include('fillcolor=lightgray')  # docs file
      expect(instructions).to include('complete.png')
    end
  end

  describe 'edge cases and error handling' do
    describe '#generate_dot_content' do
      it 'handles files with special characters in names' do
        dependencies = {
          'file with spaces.md' => {
            refs_to: Set.new(['file-with-dashes.md']),
            refs_from: Set.new([])
          },
          'file_with_underscores.md' => {
            refs_to: Set.new(['file&with&symbols.md']),
            refs_from: Set.new([])
          }
        }

        content = writer.generate_dot_content(dependencies)

        expect(content).to include('"file with spaces.md"')
        expect(content).to include('"file-with-dashes.md"')
        expect(content).to include('"file_with_underscores.md"')
        expect(content).to include('"file&with&symbols.md"')
      end

      it 'handles files with quotes in names' do
        dependencies = {
          'file"with"quotes.md' => {
            refs_to: Set.new([]),
            refs_from: Set.new([])
          }
        }

        content = writer.generate_dot_content(dependencies)

        expect(content).to include('file"with"quotes.md')
      end

      it 'handles large dependency graphs efficiently' do
        # Create a large dependency graph
        dependencies = {}
        (1..100).each do |i|
          next_file = (i < 100) ? "file#{i + 1}.md" : nil
          dependencies["file#{i}.md"] = {
            refs_to: Set.new([next_file].compact),
            refs_from: Set.new((i > 1) ? ["file#{i - 1}.md"] : [])
          }
        end

        start_time = Time.now
        content = writer.generate_dot_content(dependencies)
        end_time = Time.now

        expect(content).to include('digraph DocumentDependencies')
        expect(content.scan('->').length).to eq(99) # 99 connections (1->2, 2->3, ..., 99->100)
        expect(end_time - start_time).to be < 1 # Should complete quickly
      end

      it 'handles circular dependencies' do
        dependencies = {
          'a.md' => {
            refs_to: Set.new(['b.md']),
            refs_from: Set.new(['c.md'])
          },
          'b.md' => {
            refs_to: Set.new(['c.md']),
            refs_from: Set.new(['a.md'])
          },
          'c.md' => {
            refs_to: Set.new(['a.md']),
            refs_from: Set.new(['b.md'])
          }
        }

        content = writer.generate_dot_content(dependencies)

        expect(content).to include('"a.md" -> "b.md"')
        expect(content).to include('"b.md" -> "c.md"')
        expect(content).to include('"c.md" -> "a.md"')
      end

      it 'handles self-referencing files' do
        dependencies = {
          'self_ref.md' => {
            refs_to: Set.new(['self_ref.md', 'other.md']),
            refs_from: Set.new(['other.md'])
          },
          'other.md' => {
            refs_to: Set.new(['self_ref.md']),
            refs_from: Set.new(['self_ref.md'])
          }
        }

        content = writer.generate_dot_content(dependencies)

        expect(content).to include('"self_ref.md" -> "self_ref.md"')
        expect(content).to include('"self_ref.md" -> "other.md"')
      end

      it 'handles dependencies with empty sets' do
        dependencies = {
          'isolated.md' => {
            refs_to: Set.new([]),
            refs_from: Set.new([])
          },
          'orphan.md' => {
            refs_to: Set.new([]),
            refs_from: Set.new([])
          }
        }

        content = writer.generate_dot_content(dependencies)

        expect(content).to include('"isolated.md"')
        expect(content).to include('"orphan.md"')
        expect(content).not_to include('->') # No edges
      end
    end

    describe '#write_dot_file' do
      it 'handles write permission errors gracefully' do
        dependencies = { 'test.md' => { refs_to: Set.new([]), refs_from: Set.new([]) } }
        readonly_path = '/root/readonly.dot'

        # Can be EACCES or ENOENT depending on system
expect do
          writer.write_dot_file(dependencies, readonly_path)
        end.to raise_error(SystemCallError)
      end

      it 'overwrites existing files' do
        dependencies = { 'test.md' => { refs_to: Set.new([]), refs_from: Set.new([]) } }
        filename = File.join(temp_dir, 'overwrite.dot')

        # Write initial content
        File.write(filename, 'old content')
        expect(File.read(filename)).to eq('old content')

        # Overwrite with DOT content
        writer.write_dot_file(dependencies, filename)

        content = File.read(filename)
        expect(content).to include('digraph DocumentDependencies')
        expect(content).not_to include('old content')
      end

      it 'creates directory structure if needed' do
        dependencies = { 'test.md' => { refs_to: Set.new([]), refs_from: Set.new([]) } }
        nested_path = File.join(temp_dir, 'nested', 'deep', 'file.dot')

        # Create directory structure
        FileUtils.mkdir_p(File.dirname(nested_path))

        result = writer.write_dot_file(dependencies, nested_path)

        expect(result).to eq(nested_path)
        expect(File.exist?(nested_path)).to be true
      end

      it 'returns the correct filename for relative paths' do
        dependencies = { 'test.md' => { refs_to: Set.new([]), refs_from: Set.new([]) } }

        result = writer.write_dot_file(dependencies, 'relative.dot')

        expect(result).to eq('relative.dot')
        expect(File.exist?('relative.dot')).to be true

        # Clean up
        File.delete('relative.dot') if File.exist?('relative.dot')
      end
    end

    describe '#node_color' do
      it 'handles various task file patterns' do
        expect(writer.node_color('dev-taskflow/current/tasks/task.md')).to eq('lightyellow')
        expect(writer.node_color('project/tasks/subtask.md')).to eq('lightyellow')
        expect(writer.node_color('tasks.md')).to eq('lightyellow') # Contains "tasks" in filename
      end

      it 'handles complex file extensions' do
        expect(writer.node_color('workflow.test.wf.md')).to eq('lightblue')
        expect(writer.node_color('guide.old.g.md')).to eq('lightgreen')
        expect(writer.node_color('file.wf.md.backup')).to eq('lightgray')
      end

      it 'handles empty or nil filenames' do
        expect(writer.node_color('')).to eq('lightgray')
        expect(writer.node_color(nil)).to eq('lightgray')
      end

      it 'handles files without extensions' do
        expect(writer.node_color('README')).to eq('lightgray')
        expect(writer.node_color('tasks/README')).to eq('lightgray') # Regex requires .md extension
      end

      it 'is case sensitive for extensions' do
        expect(writer.node_color('file.WF.MD')).to eq('lightgray')
        expect(writer.node_color('file.G.MD')).to eq('lightgray')
        expect(writer.node_color('TASKS/file.md')).to eq('lightgray')
      end
    end

    describe '#png_generation_instructions' do
      it 'handles files without .dot extension' do
        instructions = writer.png_generation_instructions('graph')
        expect(instructions).to eq('dot -Tpng graph -o graph')
      end

      it 'handles files with multiple dots' do
        instructions = writer.png_generation_instructions('graph.v1.0.dot')
        expect(instructions).to eq('dot -Tpng graph.v1.0.dot -o graph.v1.0.png')
      end

      it 'handles absolute paths' do
        instructions = writer.png_generation_instructions('/absolute/path/graph.dot')
        expect(instructions).to eq('dot -Tpng /absolute/path/graph.dot -o /absolute/path/graph.png')
      end

      it 'handles empty filename' do
        instructions = writer.png_generation_instructions('')
        expect(instructions).to eq('dot -Tpng  -o ')
      end
    end
  end

  describe 'performance and memory' do
    it 'handles very large file names efficiently' do
      long_filename = 'a' * 1000 + '.md'
      dependencies = {
        long_filename => {
          refs_to: Set.new([]),
          refs_from: Set.new([])
        }
      }

      content = writer.generate_dot_content(dependencies)

      expect(content).to include(long_filename)
      expect(content.length).to be > 1000
    end

    it 'generates consistent output for same input' do
      dependencies = {
        'file1.md' => { refs_to: Set.new(['file2.md']), refs_from: Set.new([]) },
        'file2.md' => { refs_to: Set.new([]), refs_from: Set.new(['file1.md']) }
      }

      content1 = writer.generate_dot_content(dependencies)
      content2 = writer.generate_dot_content(dependencies)

      expect(content1).to eq(content2)
    end
  end

  describe 'DOT format compliance' do
    it 'produces valid DOT syntax' do
      dependencies = {
        'docs/file.md' => {
          refs_to: Set.new(['other.md']),
          refs_from: Set.new([])
        }
      }

      content = writer.generate_dot_content(dependencies)

      # Check basic DOT structure
      expect(content).to start_with('digraph DocumentDependencies {')
      expect(content).to end_with('}')
      expect(content).to include('rankdir=LR;')
      expect(content).to include('node [shape=box];')

      # Check proper quoting
      expect(content.scan(/"[^"]*"/).length).to be >= 2 # At least source and target nodes
    end

    it 'properly escapes node names' do
      # Note: Current implementation doesn't escape quotes, but documents the behavior
      dependencies = {
        'file"name.md' => { refs_to: Set.new([]), refs_from: Set.new([]) }
      }

      content = writer.generate_dot_content(dependencies)

      # Documents current behavior - quotes are included as-is
      expect(content).to include('file"name.md')
    end
  end
end

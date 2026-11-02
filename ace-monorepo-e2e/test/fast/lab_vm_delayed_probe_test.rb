# frozen_string_literal: true

require_relative "../test_helper"
require "open3"

class LabVmDelayedProbeTest < AceMonorepoE2eTestCase
  def test_subprocess_timeout_and_output_limit_are_bounded
    probe = File.expand_path("../../lab-vm/probe-forgejo-delayed-issue.py", __dir__)
    script = <<~'PY'
      import ast, os, pathlib, selectors, signal, subprocess, sys, time
      source = pathlib.Path(sys.argv[1]).read_text()
      function = next(node for node in ast.parse(source).body
                      if isinstance(node, ast.FunctionDef) and node.name == 'bounded_run')
      namespace = dict(os=os, selectors=selectors, signal=signal, subprocess=subprocess, time=time)
      exec(compile(ast.Module(body=[function], type_ignores=[]), '<probe-test>', 'exec'), namespace)
      run = namespace['bounded_run']
      started = time.monotonic()
      try:
          run(['/bin/sh', '-c', 'sleep 30 & wait'], timeout=0.3)
          raise AssertionError('subprocess timeout was not enforced')
      except subprocess.TimeoutExpired:
          assert time.monotonic() - started < 5
      try:
          run([sys.executable, '-c', 'import sys; sys.stdout.write("x" * 2000000)'], timeout=5)
          raise AssertionError('subprocess output limit was not enforced')
      except RuntimeError as error:
          assert 'output limit' in str(error)
      print('bounded')
    PY
    out, err, status = Open3.capture3("python3", "-c", script, probe)
    assert status.success?, err
    assert_equal "bounded\n", out
  end
end

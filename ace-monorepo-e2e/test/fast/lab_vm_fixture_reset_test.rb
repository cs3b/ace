# frozen_string_literal: true
require_relative "../test_helper"
require "open3"

class LabVmFixtureResetTest < AceMonorepoE2eTestCase
  def test_reset_requires_owned_identity_and_verified_export_and_retains_runtime
    probe = File.expand_path("../../lab-vm/reset-fixture.py", __dir__)
    script = <<~'PY'
      import hashlib, json, os, pathlib, runpy, sys, tempfile
      from types import SimpleNamespace
      from unittest.mock import Mock
      module = runpy.run_path(sys.argv[1])
      reset = module['FixtureReset']
      with tempfile.TemporaryDirectory() as tmp:
          root = pathlib.Path(tmp)
          run, vm = 'a' * 16, '12345678-1234-1234-1234-123456789abc'
          fixture = reset(run, vm, root=root)
          for directory in ('var/lib/ace-e2e', 'etc/lab/ace-lab', 'etc/profile.d',
                            'etc/systemd/system', 'opt/ace/runtime/bin', 'lab/ace',
                            'home/mo/.config/ace-e2e', 'home/mo/.config/herdr',
                            'home/mo/.local/state/herdr'):
              (root / directory).mkdir(parents=True, exist_ok=True)
          fixture.marker.write_text(json.dumps({'run_id': run, 'vm_uuid': vm}))
          fixture.baseline.write_text('runtime: baseline\n')
          (root / 'etc/lab/ace-lab/install.yml').write_text('runtime: fixture\n')
          (root / 'etc/profile.d/ace-e2e.sh').write_text(
              'export ACE_TOOLCHAIN=installed\nexport HERDR_SOCKET_PATH=/run/lab/herdr/herdr.sock\n')
          (root / 'opt/ace/runtime/bin/ace-lab').write_text('retained runtime')
          (root / 'lab/ace/task').write_text('old work')
          session = root / 'tmp/ace-session-test'
          session.mkdir(parents=True)
          (session / 'auth.json').write_text('private model credential')
          reset.session_paths.__globals__['pwd'] = SimpleNamespace(getpwnam=lambda _: SimpleNamespace(pw_uid=os.getuid()))
          (root / 'home/mo/.config/ace-e2e/secret').write_text('old credential')
          (root / 'home/mo/.config/herdr/session.json').write_text('old native panes')
          (root / 'home/mo/.local/state/herdr/state.json').write_text('old native state')
          run_mock = Mock()
          reset.clear.__globals__['subprocess'] = type('Commands', (), {'run': run_mock})
          def refused(action):
              try: action()
              except RuntimeError: return
              raise AssertionError('unsafe reset was accepted')
          fixture.marker.write_text(json.dumps({'run_id': 'b' * 16, 'vm_uuid': vm}))
          refused(lambda: fixture.clear('c' * 64))
          fixture.marker.write_text(json.dumps({'run_id': run, 'vm_uuid': vm}))
          refused(lambda: fixture.clear('c' * 64))
          fixture.archive.write_bytes(b'private exported evidence')
          refused(lambda: fixture.clear('c' * 64))
          assert run_mock.call_count == 0
          (root / 'lab/ace-link').symlink_to(root / 'opt/ace/runtime')
          expected = hashlib.sha256(fixture.archive.read_bytes()).hexdigest()
          result = fixture.clear(expected)
          assert result['runtime'] == 'retained'
          assert list((root / 'lab').iterdir()) == []
          assert (root / 'opt/ace/runtime/bin/ace-lab').read_text() == 'retained runtime'
          assert (root / 'etc/lab/ace-lab/install.yml').read_text() == 'runtime: baseline\n'
          assert not (root / 'home/mo/.config/ace-e2e').exists()
          assert not (root / 'home/mo/.config/herdr').exists()
          assert not (root / 'home/mo/.local/state/herdr').exists()
          assert not fixture.marker.exists()
          assert not session.exists()
          assert 'HERDR_SOCKET_PATH' not in (root / 'etc/profile.d/ace-e2e.sh').read_text()
          # A second scenario can repopulate native pane state; resetting that
          # distinct run clears it again without touching the installed tools.
          second = reset('b' * 16, vm, root=root)
          second.marker.write_text(json.dumps({'run_id': 'b' * 16, 'vm_uuid': vm}))
          second.baseline.write_text('runtime: baseline\n')
          second.archive.write_bytes(b'second private exported evidence')
          for directory in ('home/mo/.config/herdr', 'home/mo/.local/state/herdr'):
              (root / directory).mkdir(parents=True)
              (root / directory / 'session.json').write_text('{"panes":["second-run"]}')
          (root / 'lab/new-task').write_text('second run task')
          second.clear(hashlib.sha256(second.archive.read_bytes()).hexdigest())
          assert not (root / 'home/mo/.config/herdr').exists()
          assert not (root / 'home/mo/.local/state/herdr').exists()
          assert list((root / 'lab').iterdir()) == []
          assert (root / 'opt/ace/runtime/bin/ace-lab').read_text() == 'retained runtime'
    PY
    _out, err, status = Open3.capture3("python3", "-c", script, probe)
    assert status.success?, err
  end

  def test_reset_refuses_symlinked_managed_path_before_mutation
    probe = File.expand_path("../../lab-vm/reset-fixture.py", __dir__)
    script = <<~'PY'
      import pathlib, runpy, sys, tempfile
      reset = runpy.run_path(sys.argv[1])['FixtureReset']
      with tempfile.TemporaryDirectory() as tmp:
          root = pathlib.Path(tmp)
          (root / 'lab').symlink_to(root / 'outside')
          try:
              reset('a' * 16, '12345678-1234-1234-1234-123456789abc', root=root).verify()
          except RuntimeError as error:
              assert 'symlink' in str(error)
          else:
              raise AssertionError('symlink accepted')
    PY
    _out, err, status = Open3.capture3("python3", "-c", script, probe)
    assert status.success?, err
  end
end

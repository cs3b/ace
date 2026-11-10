# frozen_string_literal: true

require_relative "../test_helper"
require "open3"

class LabVmLeaseEvidenceTest < AceMonorepoE2eTestCase
  def test_probe_requires_live_access_containment_and_remote_denial
    probe = File.expand_path("../../lab-vm/lease-fault-evidence.py", __dir__)
    script = <<~'PY'
      import contextlib, datetime, io, json, os, pathlib, runpy, sys, tempfile
      from unittest.mock import Mock

      module = runpy.run_path(sys.argv[1])
      probe = module['probe']
      lease = 'lease-' + 'a' * 16
      unit = 'ace-auth-session-worker-' + 'b' * 16 + '.service'
      group = '/sys/fs/cgroup/' + unit + '/ace-exec-' + 'c' * 32
      issuer_id, session_id = 'd' * 32, 'e' * 32
      token = 'f' * 40
      now = datetime.datetime(2026, 11, 10, 10, 28, 0, 990000, tzinfo=datetime.timezone.utc)

      class FixtureDateTime(datetime.datetime):
          @classmethod
          def now(cls, tz):
              return now.astimezone(tz)

      use_until = now + datetime.timedelta(seconds=180)
      record = dict(id=lease, session_unit=unit, role='worker', repos=[module['REPOSITORY']],
                    issuer_invocation=issuer_id, session_id=session_id, state='issued',
                    execution='in-progress', execution_cgroup=group,
                    requested_at=(use_until - datetime.timedelta(seconds=60)).isoformat(),
                    use_until=use_until.isoformat())

      def exercise(mode, after, cleanup_at):
          with tempfile.TemporaryDirectory() as tmp:
              directory = pathlib.Path(tmp)
              path = directory / (lease + '.json')
              path.write_text(json.dumps(record))
              final = {k: v for k, v in record.items() if k not in ('execution', 'execution_cgroup')}
              final.update(state='revoked', cleanup=dict(result='revoked', at=cleanup_at.isoformat()))
              statuses = iter([200, after])
              def forgejo_status(value):
                  assert value == token
                  status = next(statuses)
                  if mode == 'expiry' and status == 200 and path.read_text() == json.dumps(record):
                      path.write_text(json.dumps(final))
                  return status

              kill = Mock(side_effect=lambda *_args, **_kwargs: path.write_text(json.dumps(final)))
              probe.__globals__.update(LEASES=directory, datetime=FixtureDateTime,
                  subprocess=type('Systemctl', (), {'run': kill}),
                  os=type('Root', (), {'geteuid': lambda: 0, 'path': os.path}),
                  populated=Mock(side_effect=[True, True, True, False] if mode == 'crash'
                                 else [True, True, False]),
                  invocation=lambda target: session_id if target == unit else issuer_id,
                  credential=lambda *_: (directory / 'removed', token), forgejo_status=forgejo_status)
              output = io.StringIO()
              error = None
              with contextlib.redirect_stdout(output):
                  try:
                      probe(mode, lease)
                  except module['EvidenceError'] as failure:
                      error = str(failure)
              assert token not in output.getvalue()
              rows = [json.loads(line) for line in output.getvalue().splitlines()]
              assert rows[0]['before']['http_status'] == 200
              if mode == 'crash':
                  assert kill.call_args.args[0][1:] == [
                      'kill', '--kill-whom=main', '--signal=SIGKILL', module['ISSUER']]
              else:
                  kill.assert_not_called()
              return rows, error

      rows, error = exercise('crash', 401, now)
      assert error is None and rows[-1]['after']['http_status'] == 401
      rows, error = exercise('expiry', 403, use_until)
      assert error is None and rows[-1]['after']['http_status'] == 403
      rows, error = exercise('expiry', 403, now)
      assert len(rows) == 1 and 'before expiry' in error
      rows, error = exercise('crash', 200, now)
      assert len(rows) == 1 and 'did not reject' in error
      rows, error = exercise('crash', 401, use_until)
      assert len(rows) == 1 and 'natural expiry' in error
    PY
    _out, err, status = Open3.capture3("python3", "-c", script, probe)
    assert status.success?, err
  end
end

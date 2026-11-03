#!/bin/sh
# Disposable Linux primitive probe. It does not launch an ACE session.
set -eu

[ "$#" -eq 0 ] && [ "$(id -u)" -eq 0 ] || { echo 'run as root without arguments' >&2; exit 2; }
exec unshare --mount --fork /bin/sh -s <<'PROBE'
set -eu
mount --make-rprivate /
probe_dir=$(mktemp -d /tmp/ace-idmap-probe.XXXXXXXX)
cleanup() {
  umount "$probe_dir/project" 2>/dev/null || :
  umount "$probe_dir/unmapped" 2>/dev/null || :
  rm -rf -- "$probe_dir"
}
trap cleanup EXIT
chmod 755 "$probe_dir"
mkdir "$probe_dir/project" "$probe_dir/unmapped"
project_uid=$(id -u mo)
project_gid=$(id -g mo)
session_id=200123
if getent passwd "$session_id" >/dev/null || getent group "$session_id" >/dev/null; then
  echo 'probe session identity is already allocated' >&2
  exit 1
fi
chown "$project_uid:$project_gid" "$probe_dir/project"
runuser -u mo -- env HOME="$probe_dir" GIT_CONFIG_NOSYSTEM=1 git -C "$probe_dir/project" init -q
runuser -u mo -- env HOME="$probe_dir" GIT_CONFIG_NOSYSTEM=1 git -C "$probe_dir/project" config user.email e2e@example.invalid
runuser -u mo -- env HOME="$probe_dir" GIT_CONFIG_NOSYSTEM=1 git -C "$probe_dir/project" config user.name E2E
runuser -u mo -- env HOME="$probe_dir" GIT_CONFIG_NOSYSTEM=1 sh -c '
  echo seed > "$1/README"
  git -C "$1" add README
  git -C "$1" commit -qm seed
' sh "$probe_dir/project"

mount --bind "$probe_dir/project" "$probe_dir/unmapped"
if setpriv --reuid="$session_id" --regid="$session_id" --clear-groups \
  sh -c 'test -w "$1"' sh "$probe_dir/unmapped"; then
  echo 'session identity unexpectedly has direct write access' >&2
  exit 1
fi
mount --bind -o "X-mount.idmap=u:$project_uid:$session_id:1 g:$project_gid:$session_id:1" \
  "$probe_dir/project" "$probe_dir/project"
[ "$(stat -c '%u:%g' "$probe_dir/project")" = "$session_id:$session_id" ]
setpriv --reuid="$session_id" --regid="$session_id" --clear-groups \
  env HOME="$probe_dir" GIT_CONFIG_NOSYSTEM=1 git -C "$probe_dir/project" \
  worktree add -qb test "$probe_dir/project/.ace-wt/test"
setpriv --reuid="$session_id" --regid="$session_id" --clear-groups \
  env HOME="$probe_dir" GIT_CONFIG_NOSYSTEM=1 sh -c '
    echo change >> "$1/.ace-wt/test/README"
    git -C "$1/.ace-wt/test" add README
    git -C "$1/.ace-wt/test" commit -qm change
  ' sh "$probe_dir/project"
[ "$(stat -c '%u:%g' "$probe_dir/unmapped/.ace-wt/test/README")" = "$project_uid:$project_gid" ]
[ "$(runuser -u mo -- env HOME="$probe_dir" GIT_CONFIG_NOSYSTEM=1 git -C "$probe_dir/unmapped" rev-list --count test)" = 2 ]
printf 'idmapped temporary Git worktree: pass (project ownership retained)\n'
PROBE

#!/bin/sh
# Disposable systemd/mount primitive probe; it does not launch an ACE worker.
set -eu
[ "$#" -eq 0 ] && [ "$(id -u)" -eq 0 ] || { echo 'run as root without arguments' >&2; exit 2; }
[ -d /var/lib/ace-e2e ] && [ ! -L /var/lib/ace-e2e ] && \
  [ "$(stat -c '%u:%a' /var/lib/ace-e2e)" = '0:755' ] || { echo 'unsafe probe parent' >&2; exit 1; }
probe_dir=$(mktemp -d /var/lib/ace-e2e/idmap-unit.XXXXXXXX)
unit="ace-e2e-idmap-$(cat /proc/sys/kernel/random/uuid).service"
attempted=0
runner=
watcher=
cleanup() {
  rc=$?
  stopped=1
  trap - EXIT
  if [ "$attempted" -eq 1 ]; then
    if ! /usr/bin/systemctl stop "$unit"; then
      echo "Could not stop $unit; preserve $probe_dir for diagnosis" >&2
      rc=1
      stopped=0
    fi
  fi
  if [ -n "$runner" ] && [ "$stopped" -eq 1 ]; then
    wait "$runner" 2>/dev/null || :
  fi
  if [ -n "$watcher" ] && [ "$stopped" -eq 1 ]; then
    wait "$watcher" 2>/dev/null || :
  fi
  if [ "$rc" -eq 0 ]; then
    rm -rf -- "$probe_dir" || rc=1
  else
    echo "Probe failed; diagnostic directory: $probe_dir; unit: $unit" >&2
  fi
  exit "$rc"
}
trap cleanup EXIT
chmod 755 "$probe_dir"
mkdir "$probe_dir/project"
mkdir "$probe_dir/control"
chmod 777 "$probe_dir/control"
mkfifo "$probe_dir/control/gate" "$probe_dir/control/ready" "$probe_dir/control/done" "$probe_dir/control/pidfd-ready"
chmod 666 "$probe_dir/control/gate" "$probe_dir/control/ready" "$probe_dir/control/done" "$probe_dir/control/pidfd-ready"
owner_uid=$(id -u mo)
owner_gid=$(id -g mo)
chown "$owner_uid:$owner_gid" "$probe_dir/project"
runuser -u mo -- env HOME="$probe_dir" GIT_CONFIG_NOSYSTEM=1 git -C "$probe_dir/project" init -q
runuser -u mo -- env HOME="$probe_dir" GIT_CONFIG_NOSYSTEM=1 git -C "$probe_dir/project" config user.email e2e@example.invalid
runuser -u mo -- env HOME="$probe_dir" GIT_CONFIG_NOSYSTEM=1 git -C "$probe_dir/project" config user.name E2E
runuser -u mo -- env HOME="$probe_dir" GIT_CONFIG_NOSYSTEM=1 sh -c '
  echo seed > "$1/README"
  git -C "$1" add README
  git -C "$1" commit -qm seed
' sh "$probe_dir/project"

attempted=1
/usr/bin/systemd-run --quiet --wait --unit="$unit" --property=Type=exec --property=DynamicUser=yes \
  --property=PrivateMounts=yes --property=NoNewPrivileges=yes --property=ProtectSystem=strict \
  --property=Delegate=yes --property="ReadWritePaths=$probe_dir" \
  /usr/bin/env HOME="$probe_dir" GIT_CONFIG_NOSYSTEM=1 /bin/bash -c '
    set -e
    exec 4<> "$1/control/ready"; printf "ready\n" >&4
    exec 3<> "$1/control/gate"; IFS= read -r -t 15 signal <&3; [ "$signal" = go ]
    git -C "$1/project" worktree add -qb test "$1/project/.ace-wt/test"
    echo change >> "$1/project/.ace-wt/test/README"
    git -C "$1/project/.ace-wt/test" add README
    git -C "$1/project/.ace-wt/test" commit -qm change
    exec 5<> "$1/control/done"; printf "done\n" >&5
    exec /bin/sleep 60
  ' bash "$probe_dir" &
runner=$!
/usr/bin/timeout 5 /bin/sh -c 'IFS= read -r signal < "$1"; [ "$signal" = ready ]' sh "$probe_dir/control/ready"
pid=$(/usr/bin/systemctl show --property=MainPID --value "$unit")
[ "$pid" -gt 0 ]
session_uid=$(stat -c '%u' "/proc/$pid")
session_gid=$(stat -c '%g' "/proc/$pid")
[ "$session_uid" -gt 0 ] && [ "$session_uid" -ne "$owner_uid" ]
/usr/bin/python3 -c 'import os,select,sys; fd=os.pidfd_open(int(sys.argv[1])); ready=os.open(sys.argv[2],os.O_RDWR); os.write(ready,b"ready\n"); sys.exit(0 if select.select([fd],[],[],20)[0] else 1)' "$pid" "$probe_dir/control/pidfd-ready" &
watcher=$!
/usr/bin/timeout 5 /bin/sh -c 'IFS= read -r signal < "$1"; [ "$signal" = ready ]' sh "$probe_dir/control/pidfd-ready"
namespace=$(stat -Lc '%d:%i' "/proc/$pid/ns/mnt")
[ "$namespace" != "$(stat -Lc '%d:%i' /proc/1/ns/mnt)" ]
exec 9<"/proc/$pid/ns/mnt"
[ "$namespace" = "$(stat -Lc '%d:%i' /proc/self/fd/9)" ]
[ "$(/usr/bin/systemctl show --property=MainPID --value "$unit")" = "$pid" ]
/usr/bin/systemctl is-active --quiet "$unit"
if /usr/bin/setpriv --no-new-privs --reuid="$session_uid" --regid="$session_gid" --clear-groups \
  sh -c 'test -w "$1"' sh "$probe_dir/project"; then
  echo 'session identity unexpectedly has direct write access' >&2
  exit 1
fi
/usr/bin/nsenter --mount=/proc/self/fd/9 -- /bin/mount --bind \
  -o "X-mount.idmap=u:$owner_uid:$session_uid:1 g:$owner_gid:$session_gid:1" \
  "$probe_dir/project" "$probe_dir/project"
exec 9<&-
[ "$(awk '/^Uid:/ {print $3}' "/proc/$pid/status")" = "$session_uid" ]
[ "$(awk '/^Gid:/ {print $3}' "/proc/$pid/status")" = "$session_gid" ]
grep -F "/$unit" "/proc/$pid/cgroup" >/dev/null
/usr/bin/timeout 5 /bin/sh -c 'printf "go\n" > "$1"' sh "$probe_dir/control/gate"
/usr/bin/timeout 10 /bin/sh -c 'IFS= read -r signal < "$1"; [ "$signal" = done ]' sh "$probe_dir/control/done"
[ "$(stat -c '%u:%g' "$probe_dir/project/.ace-wt/test/README")" = "$owner_uid:$owner_gid" ]
/usr/bin/systemctl is-active --quiet "$unit"
/usr/bin/systemctl stop "$unit"
attempted=0
wait "$runner" || :
runner=
watcher_status=0
wait "$watcher" || watcher_status=$?
watcher=
[ "$watcher_status" -eq 0 ] || { echo 'session process exit was not confirmed by pidfd' >&2; exit 1; }
[ -z "$(runuser -u mo -- env HOME="$probe_dir" GIT_CONFIG_NOSYSTEM=1 git -C "$probe_dir/project/.ace-wt/test" status --porcelain)" ]
printf 'dynamic systemd unit committed in mapped project and stopped with unit: pass\n'

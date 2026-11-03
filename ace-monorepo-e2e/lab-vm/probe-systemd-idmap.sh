#!/bin/sh
# Disposable systemd/mount primitive probe; it does not launch an ACE worker.
set -eu
[ "$#" -eq 0 ] && [ "$(id -u)" -eq 0 ] || { echo 'run as root without arguments' >&2; exit 2; }
[ -d /var/lib/ace-e2e ] && [ ! -L /var/lib/ace-e2e ] && \
  [ "$(stat -c '%u:%a' /var/lib/ace-e2e)" = '0:755' ] || { echo 'unsafe probe parent' >&2; exit 1; }
probe_dir=$(mktemp -d /var/lib/ace-e2e/idmap-unit.XXXXXXXX)
unit="ace-e2e-idmap-$(cat /proc/sys/kernel/random/uuid).service"
attempted=0
child=
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
  if [ -n "$child" ] && [ "$stopped" -eq 1 ]; then
    wait "$child" 2>/dev/null || :
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
/usr/bin/systemd-run --quiet --unit="$unit" --property=Type=exec --property=DynamicUser=yes \
  --property=PrivateMounts=yes --property=NoNewPrivileges=yes --property=ProtectSystem=strict \
  --property=Delegate=yes --property="ReadWritePaths=$probe_dir" /bin/sleep 60
pid=$(/usr/bin/systemctl show --property=MainPID --value "$unit")
[ "$pid" -gt 0 ]
session_uid=$(stat -c '%u' "/proc/$pid")
session_gid=$(stat -c '%g' "/proc/$pid")
[ "$session_uid" -gt 0 ] && [ "$session_uid" -ne "$owner_uid" ]
if /usr/bin/setpriv --no-new-privs --reuid="$session_uid" --regid="$session_gid" --clear-groups \
  sh -c 'test -w "$1"' sh "$probe_dir/project"; then
  echo 'session identity unexpectedly has direct write access' >&2
  exit 1
fi
/usr/bin/nsenter --target "$pid" --mount -- /bin/mount --bind \
  -o "X-mount.idmap=u:$owner_uid:$session_uid:1 g:$owner_gid:$session_gid:1" \
  "$probe_dir/project" "$probe_dir/project"
/usr/bin/nsenter --target "$pid" --mount -- /usr/bin/setpriv --no-new-privs \
  --reuid="$session_uid" --regid="$session_gid" --clear-groups \
  env HOME="$probe_dir" GIT_CONFIG_NOSYSTEM=1 git -C "$probe_dir/project" \
  worktree add -qb test "$probe_dir/project/.ace-wt/test"
/usr/bin/nsenter --target "$pid" --mount -- /usr/bin/setpriv --no-new-privs \
  --reuid="$session_uid" --regid="$session_gid" --clear-groups \
  env HOME="$probe_dir" GIT_CONFIG_NOSYSTEM=1 sh -c '
    echo change >> "$1/.ace-wt/test/README"
    git -C "$1/.ace-wt/test" add README
    git -C "$1/.ace-wt/test" commit -qm change
  ' sh "$probe_dir/project"
[ "$(stat -c '%u:%g' "$probe_dir/project/.ace-wt/test/README")" = "$owner_uid:$owner_gid" ]
runuser -u mo -- mkfifo "$probe_dir/project/gate" "$probe_dir/project/ready"
/usr/bin/nsenter --target "$pid" --mount -- /usr/bin/setpriv --no-new-privs \
  --reuid="$session_uid" --regid="$session_gid" --clear-groups \
  /bin/bash -c 'exec 4<> "$1/ready"; printf "ready\n" >&4; exec 3<> "$1/gate"; IFS= read -r -t 15 signal <&3; [ "$signal" = go ]; exec /bin/sleep 60' bash "$probe_dir/project" &
child=$!
/usr/bin/timeout 5 /bin/sh -c 'IFS= read -r signal < "$1"; [ "$signal" = ready ]' sh "$probe_dir/project/ready"
[ "$(awk '/^Uid:/ {print $3}' "/proc/$child/status")" = "$session_uid" ]
[ "$(awk '/^Gid:/ {print $3}' "/proc/$child/status")" = "$session_gid" ]
/usr/bin/busctl --system --no-pager --auto-start=no --allow-interactive-authorization=no call \
  org.freedesktop.systemd1 /org/freedesktop/systemd1 org.freedesktop.systemd1.Manager \
  AttachProcessesToUnit ssau "$unit" '' 1 "$child" >/dev/null
grep -F "/$unit" "/proc/$child/cgroup" >/dev/null
/usr/bin/timeout 5 /bin/sh -c 'printf "go\n" > "$1"' sh "$probe_dir/project/gate"
/usr/bin/systemctl stop "$unit"
attempted=0
child_status=0
wait "$child" || child_status=$?
child=
case "$child_status" in
  137|143) ;;
  *) echo "attached child exited unexpectedly: $child_status" >&2; exit 1 ;;
esac
[ -z "$(runuser -u mo -- env HOME="$probe_dir" GIT_CONFIG_NOSYSTEM=1 git -C "$probe_dir/project/.ace-wt/test" status --porcelain)" ]
printf 'dynamic systemd UID mapped project and stopped attached child: pass\n'

---
source: "taskflow:v.0.9.0"
---
# Idea

e2e container isolation on vm - linux 

Below is how to run a process inside a lightweight container on Arch Linux (no Docker, no VM) using LXC, and only share a specific host reports folder.

⸻

1) Install LXC on Arch

Install LXC and required tools:

sudo pacman -Syu lxc lxc-templates

Optional but recommended:

sudo pacman -S iptables dnsmasq bridge-utils

This gives you the LXC userland tools you need.  ￼

Verify kernel support:

sudo lxc-checkconfig

Ensure cgroups, namespaces, and user namespace features are enabled.  ￼

⸻

2) Create an LXC Container

Example: create an Arch Linux container (or another disto if needed):

sudo lxc-create -n myproc -t download -- --dist archlinux --release latest --arch amd64

If a direct Arch template isn’t available, you can use a generic one or the lxc-archlinux template from /usr/share/lxc/templates.  ￼

The config and filesystem are stored in:

/var/lib/lxc/myproc/


⸻

3) Share Only the Report Folder

On the host, create the shared folder:

mkdir -p ~/container_reports

This is the only folder that the container will see outside its rootfs.

Edit container config

Open the container config:

sudo nano /var/lib/lxc/myproc/config

Add:

lxc.mount.entry = /home/youruser/container_reports reports none bind,create=dir

•First path: host folder.
•Second: mount point inside container (relative to container root).
•You can add ro to restrict container to read only.  ￼

Now the container’s /reports is the host ~/container_reports.

⸻

4) Run Your Process

Option A — Run in full container

Start it:

sudo lxc-start -n myproc

Attach a shell:

sudo lxc-attach -n myproc

Inside container:

cd /reports
your_process_here

The process writes results into /reports, and the host will see them in ~/container_reports.

⸻

Option B — Run one command directly

Use lxc-execute to run a single command/process inside the container:

sudo lxc-execute -n myproc -- /reports/run_script.sh

This executes your script or binary and exits. It avoids spinning up a full interactive environment.  ￼

⸻

5) Automate Startup (Optional)

To auto-start a specific process on container start:

Add to container config:

lxc.init.cmd = /reports/run_script.sh

Then:

sudo lxc-start -n myproc

The configured process runs automatically.  ￼

⸻

6) Permissions & Unprivileged Containers
•By default, LXC uses privileged containers which run as root inside the container; host mapping is direct.
•For safer unprivileged containers with user namespace mappings, enable user namespace support and configure /etc/subuid and /etc/subgid for your host user.  ￼

This avoids root in container mapping to root on the host.

⸻

Summary (Task Steps)
1.Install LXC on Arch via pacman.  ￼
2.Create container (Arch or another base).  ￼
3.Create host reports folder and bind-mount it in container config.  ￼
4.Run your process inside container (lxc-start + lxc-attach or lxc-execute).  ￼
5.(Optional) autostart process via lxc.init.cmd.  ￼

This gives simple, non-Docker, non-VM light containerization with only the report folder shared.

---
Captured: 2026-02-21 23:11:09

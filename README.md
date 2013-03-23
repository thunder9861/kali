Custom Kali Linux
=================
---

This is a fork of:
git://git.kali.org/live-build-config.git

I wanted to have a live build environment that I can use to create a custom version of Kali Linux.

The basic idea is this:

- Build the system to create a chroot directory
- Apply an Aufs layer on the chroot directory to redirect changes to config/includes.chroot
- Start an X session in the chroot to allow complete customizations
- Git is then used to cherry pick which changes should be saved
- The config/includes.chroot is stripped of any uncommitted changes
- A fresh chroot is then created, and the process loops around to refine the system

Scripts are provided to accomplish the tasks above.
Each script is stored in the actual chroot, so the system itself can be used to bootstrap another system.
The virtualbox guest utils are also included so the live cd customizations can occur in a virtual environment, where the power of snapshots can be utilized.

---

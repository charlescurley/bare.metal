#! /bin/sh

# A script to mount file systems as neede for chrooting, then running
# grub-install while chrooted to the target. This ensures that we use
# the target grub code, which can get finicky. You should probably run
# this last.

# This is written for finnix, but should be good on pretty much any
# Linux installation that uses grub. See
# https://www.finnix.org/Restoring_bootloaders

# Copyright 2017 through the last date of modification Charles Curley.

# This program is free software; you can redistribute it and/or modify it
# under the terms of the GNU General Public License as published by the
# Free Software Foundation; either version 2 of the License, or (at your
# option) any later version.

# This program is distributed in the hope that it will be useful, but
# WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
# General Public License for more details.

# You should have received a copy of the GNU General Public License
# along with this program; if not, write to the Free Software
# Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA
# 02110-1301, USA

# You can also contact the Free Software Foundation at http://www.fsf.org/

# Now install the boot sector. N.B: if you have libata IDE drive
# issues, it won't work. If it doesn't, use your rescue disk to do the
# same. If grub-install fails, you may be able to chroot, and then run
# grub-install from inside the chroot environment.

BOOTDEV=$(ls /dev/[shv]da /dev/nvme[0-9]n[0-9])

# prep for chroot
mount -t proc none /target/proc
mount -t sysfs none /target/sys
mount --bind /dev /target/dev

# chroot $target /sbin/lilo -C /etc/lilo.conf
chroot $target /usr/sbin/grub-install $BOOTDEV

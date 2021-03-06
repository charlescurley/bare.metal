#! /bin/bash

# A script to restore all of the data to tester via ssh. This is our final
# stage restore.

# Copyright 2000 Charles Curley.

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

# For more information contact the author, Charles Curley, at
# http://www.charlescurley.com/.

# 2007-05-22: Changes for FHS compliance. Removed commented out
# references to ZIP drives.

# 2006-04-14: Use the script ../scripts/get.target to determine the
# host name. This makes the script more general, and maybe we can run
# it from one place & determine the host name from the directory
# name.

# Get the host name of the computer to be backed up and other info.
. ../scripts/get.target

bunzip2 -dc $TARGET.tar.bz2 | ssh $host "umask 000 ; cd / ; tar -xpkf - "

# bunzip2 -dc $host.dos.$DATE.tar.bz2 | ssh $host "umask 000 ;\
# mount /mnt/dosc ; cd / ; tar -xpkf - "

# Note libata issue! We boot to /dev/sda, not /dev/hda, as IDE drives
# now show up as SCSI drives.

ssh $host "chown root:lock /var/lock ; grub-install /dev/sda"
# ; chown -R amanda:disk /var/lib/amanda

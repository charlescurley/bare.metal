#! /bin/bash

# Back up another computer's drive to this system. To make this work,
# we need a convenient chunk of disk space on this computer. This
# version uses ssh to do its transfer, and compresses using bz2. This
# version was developed so that the system to be backed up won't be
# authenticated to log onto the backup computer. This script is
# intended to be used on a firewall. You don't want the firewall to be
# authenticated to the backup system in case the firewall is cracked.

# Copyright 2000 through the last date of modification Charles Curley.

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
# references to ZIP drives. Now, if the archive does not exist on the
# client, we run save.metadata there.

# 2006-04-14: Use the script ../scripts/get.target to determine the
# host name. This makes the script more general, and maybe we can run
# it from one place & determine the host name from the directory
# name. Also, we now test to see if old backups exist before deleting
# them.

# 2004 04 03: added /sys to the list of excludes. It is a read-only
# pseudo-file system like /proc.

# 2002 07 01: We now set the path on the target to the zip drive with
# a variable. This fixes a bug in the command to eject the zip disk.

# 2002 07 01: The zip disk archives are now in bzip2 format, so this
# script has been changed to reflect that.

# Get the host name of the computer to be backed up and other info.
. ../scripts/get.target

# The "--anchored" option is there to prevent --exclude from excluding
# all files with that name. E.g. we only want to exclude /sys, not
# some other sys elsewhere in the file system.

ssh $host "cd / ; tar -cf - --anchored --exclude media --exclude mnt\
 --exclude selinux --exclude sys --exclude proc --exclude var/spool/squid\
 --exclude var/cache/yum --exclude var/named/chroot/proc\
 --exclude var/lib/bare.metal.recovery * " | bzip2 -9 | cat > $host.$DATE.tar.bz2

# if [ -e $host.dos.$DATE.old.tar.bz2 ] ; then
#     rm $host.dos.$DATE.old.tar.bz2
# fi

# echo Backing up $host dos to the backup server.
# ssh $host "cd / ; mount mnt/dosc ; tar -cf - mnt/dosc "\
# | bzip2 -9 | cat > $host.dos.$DATE.tar.bz2

echo Testing the results.
find $host.$DATE* -iname "*.bz2" | xargs bunzip2 -t

# Post-processing.
. ../scripts/post.sh

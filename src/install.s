#! /bin/bash

# A script to install the bare metal recovery scripts. With any luck,
# this will comply with the "Filesystem Hierarchy Standard",
# http://www.pathname.com/fhs/, version 2.3, announced on January 29,
# 2004.

# Copyright 2007 through the last date of modification, Charles Curley.

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

# You can also contact the Free Software Foundation at
# http://www.fsf.org/

# 2017-07-12: We now check to see if the perl UUID module is installed
# and in perl's module path.

# 2014-01-06: we now install a set of excludes for use in general
# backing up of stuff not backed up by the general backup system
# (amanda, e.g., or by the metatdata/minimal system backups.

# Begin the actual code.

# Check for the presence of perl's UUID module (and, indirectly, perl
# itself).

perl -e 'use UUID;'
uuid=$?

if [ "$uuid" != "0" ] ; then
    echo Oops! Please install perl module UUID.
    echo E.g.: apt install libuuid-perl
    echo Perl exited with a return value of $uuid.
    exit $uuid
fi

# Where we put the archives ready for making CDs, etc.
mkdir -p /var/lib/bare.metal.recovery

# Keep them secure from pesky snooping users who don't need to be able
# to hack a copy of, say, /etc/shadow.
chmod 700 /var/lib/bare.metal.recovery

# Excludes for use by the "get" script on the bare metal backup
# server.
cp ../bare.metal.backup.excludes /var/lib/bare.metal.recovery

# Backup time executables.
for i in save.metadata make.fdisk ; do
  cp -rp $i /usr/sbin
  chown root:root /usr/sbin/$i
done

# Save the recovery time executables we provide. The archiving
# programs look for them here and save them into the archives.
mkdir -p /etc/bare.metal.recovery
for i in first.stage restore.metadata install.grub ; do
  cp -rp $i /etc/bare.metal.recovery
  chown root:root /etc/bare.metal.recovery/$i
done

if [ ! "$(grep -c '^processor[[:blank:]]*: [[:digit:]]*$' /proc/cpuinfo)" = "1" ] &&
       test -z "$(command -v pbzip2)" ; then
    echo "Multiprocessor! This program would benefit from pbzip2.";
    echo "E.g.: apt install pigz pbzip2";
fi

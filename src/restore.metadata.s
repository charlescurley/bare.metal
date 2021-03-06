#! /bin/sh

# A script to restore the meta-data from the ZIP disk. This runs under
# tomsrtbt only after partitions have been rebuilt, file systems made,
# and mounted. It also assumes the ZIP disk has already been
# mounted. Mounting the ZIP disk read only is probably a good idea.

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

# 2007-07-08: We now force inittab to run level 3, which may be disty
# dependent. FHS compliance changes as well.

# 2005-08-03: We now use a relative path, so you can load from
# different places depending on the first stage system you are
# using. Also added some FC4 tricks, and some changes to better
# reproduce the permissions and ownerships.

# 2003 08 23: Oops: tar on tomsrtbt does not respect -p. Try setting
# umask to 0000 instead.

# 2003 02 13: Tar was not preserving permissions on restore. Fixed
# that.

# 2002 07 01: Went to bzip2 to compress the archives, for smaller
# results. This is important in a 100MB ZIP disk. Also some general
# code cleanup.

# For more information contact the author, Charles Curley, at
# http://www.charlescurley.com/.

umask 0000

cd ..                    # Assume we are in /bin
zip=$(pwd)/data;         # Where we find the tarballs to restore.
target="/target";        # Where the hard drive to restore is mounted.

ls -lt $zip/*.bz2        # Warm fuzzies for the user.

cd $target

# Restore the archived metadata files.
for archive in $( ls $zip/*.bz2 ); do
  echo $archive
  ls -al $archive
  bzip2 -dc $archive | tar -xf -
done

# Build the mount points for our second stage restoration and other
# things.

# If you boot via an initrd, make sure you build a directory here so
# the kernel can mount the initrd at boot. tmp/.font-unix is for the
# xfs font server.

for dir in\
   back\
   dev\
   initrd\
   media/disk\
   mnt/dosc\
   mnt/imports\
   mnt/nfs\
   mnt/zip\
   proc\
   selinux\
   sys\
   tmp/.font-unix\
   usr/share\
   var/cache/yum\
   var/empty/sshd/etc\
   var/lib/bare.metal.recovery\
   var/lock/subsys\
   var/log\
   var/run\
   var/spool\
 ; do

  mkdir -p $target/$dir
done

for dir in mnt usr usr/share $(ls -d var/*) selinux usr/lib var \
  var/cache/yum var/lock/subsys var/empty/sshd/etc \
  var/spool media ; do
  chmod go-w $target/$dir
done

# Set modes
chmod 0111 $target/var/empty/sshd
# chmod 777 $target/var/lock
# chmod o+t $target/var/lock
chmod 777 $target/run/lock
chmod o+t $target/run/lock
pushd $target ; ln -s run/lock var/lock ; popd
chmod 711 $target/var/empty/sshd
chmod 700 $target/var/lib/bare.metal.recovery

# For Fedora. First two for xfs.
# chroot $target chown xfs:xfs /tmp/.font-unix
# chmod 1777 $target/tmp/.font-unix # set the sticky bit.
chmod 1777 $target/tmp

# Set the system to boot to run level 3 regardless of the current run
# level. Be sure to set it back to the normal value.

if [ -e $target/etc/inittab ] ; then
  sed -i s/id:.:initdefault:/id:3:initdefault:/g $target/etc/inittab
fi

df -m

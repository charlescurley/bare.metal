#! /bin/bash

# A master script to run the other, detailed scripts. Use this script
# only if you want no human intervention in the restore process. The
# only option is -c, which forces bad block checking during formatting
# of the partitions.

# Copyright 2002 through the last date of modification Charles Curley.

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

# 2005-08-07 We no longer assume the working directory. This is
# because the working directory will vary greatly according to which
# Linux disty you use and how you are doing your restoration.

export blockcheck=$1;

if [ "$blockcheck" != "-c" ] && [ -n "$blockcheck" ]
then
    echo "${0}: automated restore with no human interaction."
    echo "${0}: -c: block check during file system making."
    exit 1;
fi

for drive in $( ls make.dev.* ); do
    echo "$drive"$'\a'
    sleep 2
    ./"$drive" "$blockcheck";
done

# If there are any LVM volumes, now is the time to restore them.

if [ -e make.lvs ] && [ -e mount.lvs ]
then
    echo make.lvs$'\a'
    sleep 2
    ./make.lvs

    echo mount.lvs$'\a'
    ./mount.lvs
fi


# WARNING: If your Linux system mount partitions across hard drive
# boundaries, you will have multiple "mount.dev.* scripts. You must
# ensure that they run in the proper order, which the loop below may
# not do. The root partition should be mounted first, then the rest in
# the order they cascade. If they cross mount, you'll have to handle
# that manually. If you have LVMs to deal with, that's a whole 'nother
# kettle of fish.

# The "ls -tr" will list the scripts in the order they are created, so
# it might be a good idea to create them (in the script save.metadata)
# in the order in which you should run them.

for drive in $( ls -tr mount.dev.* ); do
    echo "$drive"$'\a'
    sleep 2
    ./"$drive";
done

./restore.metadata

echo Installing grub now.
./install.grub

# People who are really confident may comment this line in.
# reboot

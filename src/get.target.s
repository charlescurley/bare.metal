# -*- shell-script -*-

# Copyright 2000 through the last date of modification, Charles Curley.

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

# How to determine the target: the directory structure is
# /..../back/hostname.OS.etc So we have to get the name of the
# directory. That gives us host name and OS.etc. From that we extract
# the host name.

path=$(pwd)

target=${path##/*/}
host=${target%%.*}

# Run "info date" for more information.

DATE=$(date +%Y%m%d)
# echo "Today's date is $DATE."

echo "\$target is $target. \$host is $host. Today's date is $DATE."

name=$0
echo "This is script $name"

if [ $(echo "$name" | grep -i get > /dev/null) ] ; then
    # Do functions common to all restores.

    # Which archive do we restore and is this a valid target name?

    TARGET=$1

    if [ -z "$TARGET" ] ; then
        echo Please specify a target from one of:
        for dir in $(ls -d "$host".*) ; do
            if [ -d "$dir" ] ; then
                echo -n "$dir "
            fi
        done
        exit 2;
    fi

    if [ -z "$TARGET" ] || [ ! -d "$TARGET" ] ; then
        echo "$TARGET" does not exist!
        exit 2;
    fi

    ssh "$host" rm -r /var/lib/rpm
else
    # Do functions common to all gets.

    # Where we will get the archives on the target.

    #zip=/mnt/zip
    export zip="/var/lib/bare.metal.recovery";

    # If it does not already exist, build the archive.

    ssh "$host" "if [ ! -d ${zip}/$DATE ] ; then echo Saving metadata... ; save.metadata ; fi"

    echo Backing up "$host"

    if [ -e "$host.$DATE" ] ; then
	    rm -r "$host.$DATE"
    fi

    echo Copying the bare metal recovery archive.

    # -r for recursive copy, -p to preserve times and permissions, -q
    # for quiet: no progress meter.

    scp -qpr "$host:$zip/$DATE" "$host.$DATE"

    du -hs "$host".*

    echo Cleaning out old yum packages
    ssh "$host" "yum clean packages"

    echo Backing up "$host" to the backup server.

    if [ -e "$host.$DATE".tar.bz2 ] ; then
        rm "$host.$DATE".tar.bz2
    fi
fi

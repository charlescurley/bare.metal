#! /bin/bash

# A script to save certain meta-data off to the boot partition. Useful for
# restoration.

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

# 2013-06-14: Preliminary work on preserving GPT information. We have
# not automated restoring, but at least we preserve the partition
# data.

# 2013-05-09: We now accumulate LSB release data into the README.txt
# file.

# 2012-07-18: Added creation of a list of packages, for debian systems
# only.

# 2007-10-29: added support for Debian systems.

# 2007-05-22: Changes for FHS compliance. Removed commented out
# references to ZIP drives. Added a line to deal with the fact that
# libata (in newer kernels) maps IDE drives to SCSI device names, but
# not all rescue distributions use libata. So we have to change the
# device names from SCSI to IDE, e.g. /dev/sda to /dev/hda.

# 2006-03-26: had a deprecated option in the sort options; fixed that.

# 2005-09-09: Added a line to create a boot disk ISO in the ZIP drive.

# 2005-08-30: Modernized sub-shell calls, a few other tweaks.

# 2005-07-29: Fedora Core 4 mods. Name of the directory to be saved
# has to be last. Also, we now specify --numeric-owner so as to avoid
# UID problems when using some live CD systems. And we now save to
# /var instead of a mounted ZIP disk.

# 2005-02-19: Fedora Core 3 mods.

# 2003 01 08: We now age the output from rpm -VA to make back
# comparisons easier.

# The loop that creates directories now has the -p option for mkdir,
# which means you can create parents on the fly if they don't already
# exist.

# initrd is now in the list of directories to create automatically.

# We now exclude more stuff when building the tarballs.

# 2002 07 01: Went to bzip2 to compress the archives, for smaller
# results. This is important in a 100MB ZIP disk. Also some general
# code cleanup.

# 2002 07 01: The function crunch will tar and bzip2 the
# archives. This is cleaner than the old code, and has better safety
# checking.


# For more information contact the author, Charles Curley, at
# http://www.charlescurley.com/.

# Exclude: given a fully qualified path to an ambiguous file name,
# expand it to the base name plus, e.g. any version numbering in the
# base name. E.g. "/usr/lib/python*" becomes "python2.5" if that's
# what's in the directory. We then prepend "--exclude" and return
# it. Use it to prepare ambiguous excludes for crunch's benefit. If
# the file doesn't exist, we return nothing.

function exclude {

if [ -z "$1" ]; then            # 0 length parameter check.
   echo "-Parameter #1 is missing.-" # Also if no parameter is passed.
   exit 1
else
   local file=$1
   local t
   for t in $(ls -d $file 2>/dev/null ) ; do
     if [ -e $t ]; then
       echo -n '--exclude ' ${t#/} ' ' ;
     fi
   done
fi
}


# Crunch: A function to compress the contents of a directory and put
# the archive onto the ZIP disk.

# The first parameter is the name of the archive file to be
# created. The backup location, $zip, will be prepended and the
# extension, "tar.bz2" will be appended.

# All following parameters will be taken as additional directories or
# files to be put into the archive.

function crunch {

if [ -z "$1" ] || [ -z "$2" ]	# Checks if parameter #1 or #2 is zero length.
then
   echo "-Parameter #1 or #2 is missing.-"  # Also if no parameter is passed.
   return 1
else
   local file=$1		# The archive file to create
   shift			# Discard the file name
   local dirs=$@		# The director[y|ies] to archive
   local tarcmd="tar --numeric-owner -cjf"	# The tar command.

   local tarit="$tarcmd  ${zip}/$data/$file.tar.bz2 $dirs"
   echo $tarit
   $tarit			# do it!!

   error=$?			# Preserve the exit code

   if [ $error != 0 ]		# Did we fail?
   then				# Yes
      echo "Tar failed with error $error"
      echo $tarcmd ${zip}/$data/$file.tar.bz2 $dirs
      exit $error		# return tar's exit code as ours
   fi

   return 0			# For error testing if needed.
fi
}

# Begin the main line code
export data="data";             # Name of the data directory in the archive
export today=$(date +%Y%m%d);   # Today's archive
export zip="/var/lib/bare.metal.recovery/${today}";

if [ -d ${zip} ] ; then
  echo deleting metadata from earlier today,
  echo ${zip}
  echo
  rm -r ${zip}
fi
mkdir -p ${zip}/metadata ${zip}/bin ${zip}/data

NEW=${zip}/metadata/rpmVa.txt       # name for the rpm -Va output file.

# Now we save hard drive information. Run make.fdisk on each hard
# drive in the order in which it mounted from the root partition. That
# is, run it first on the hard drive with your root partition, then
# any hard drives that mount to the first hard drive, then any hard
# drives that mount to those. For example, if your root partition is
# on /dev/sdc, run "make.fdisk /dev/sdc" first.

# The reason for this is that make.fdisk produces a script to make
# mount points and then mount the appropriate partition to them during
# first stage restore. Mount points must be created on the partition
# where they will reside. The partitions must be mounted in this
# order. For example, if your /var and /var/ftp are both separate
# partitions, then you must mount /, create /var, then mount /var,
# then create /var/ftp. The order in which the script "first.stage"
# runs the mounting scripts is based on their time of creation.

# If necessary, put a line, "sleep 1" between calls to make.fdisk.

echo "Saving hard drive info"

# List all your hard drives here. Put them in the order you want
# things done at restore time.

# for drive in sda ; do
for drive in $(ls /dev/[hsv]d? | cut -c6-10) ; do
    echo Processing drive ${drive}
    fdisk -l /dev/${drive} | grep GPT > /dev/null
    if [ $? = '0' ] ; then
        echo "GPT found."
	sgd=$(which sgdisk)
        if [ $? = '1' ] ; then
            echo "sgdisk required ; install package gdisk!"
            exit 1
        fi
	sgdisk -p /dev/${drive} > ${zip}/sgdisk.${drive}.txt
	sgdisk --backup=${zip}/metadata/sgdisk.${drive} /dev/${drive}
    else
        echo "GPT not found. Handling as usual."
        make.fdisk /dev/${drive}
        fdisk -l /dev/${drive} > ${zip}/fdisk.${drive}
    fi
done

echo -e "$(hostname) bare metal archive, created $(date)" > ${zip}/README.txt
uname -a >> ${zip}/README.txt

# Preserve the release information. Tested with Red Hat/Fedora, should
# work with SuSE, Mandrake and other RPM based systems. Also Ubuntu
# 7.10, Gutsy Gibbon.

for releasefile in $(ls /etc/*release*  /etc/debian_version) ; do
  # echo $releasefile
  if [ -e $releasefile ] && [ ! -L $releasefile ] ; then
    cat $releasefile >> ${zip}/README.txt
  fi
done

# Linux Standard Base information.

lsb=$(which lsb_release)

if [ $? = '0' ] ; then
  echo >> ${zip}/README.txt
  echo LSB data: >> ${zip}/README.txt
  lsb_release -a >> ${zip}/README.txt
fi

# end Linux Standard Base information.

# Are we on an RPM based system? Suse?? Other RPM systems?
REDHAT=$(grep -iq \(fedora\|redhat\) ${zip}/README.txt ; echo $?)

ifconfig > ${zip}/ifconfig

if [ $REDHAT == 0 ] ; then

    # back up RPM metadata
    echo "Verifying RPMs."
    rpm -Va | sort -t ' ' -k 3 | uniq > ${NEW}
    echo "Finished verifying RPMs."

else
    echo "Non-RPM System."
    apt-get clean
    apt-get autoremove
    dpkg-query --showformat='${Package}\t${Version}\t${Revision}\t${Architecture}\n' --show | sort > ${zip}/packages.txt
    if [ -z $(which debsums) ] ; then
        echo debsums is *not* intalled.
    else
        echo Running debsums...
        debsums -csa > ${zip}/metadata/debsums.txt 2>&1
        echo Done running debsums.
    fi
fi

echo "Building the ZIP drive backups."

# These are in case we need to refer to them while rebuilding. The
# rebuilding process should be mostly automated, but you never
# know....

ls -al /mnt > ${zip}/ls.mnt.txt
ls -al / > ${zip}/ls.root.txt
ls -al /var > ${zip}/ls.var.txt

cd /

# Build our minimal archives on the ZIP disk. These appear to be
# required so we can restore later on.

crunch usr.lib \
$(exclude 'usr/lib/anaconda*') \
$(exclude 'usr/lib/evolution*') \
$(exclude 'usr/lib/firefox*') \
$(exclude 'usr/lib/gimp*') \
$(exclude 'usr/lib/ImageMagick*') \
$(exclude 'usr/lib/libgucharmap*' ) \
$(exclude 'usr/lib/libkdeui*' ) \
$(exclude 'usr/lib/libmwaw*' ) \
$(exclude 'usr/lib/llvm*' ) \
$(exclude 'usr/lib/perl*') \
$(exclude 'usr/lib/python*') \
$(exclude 'usr/lib/qt*') \
$(exclude 'usr/lib/x86_64-linux-gnu/perl*' ) \
--exclude usr/lib/Adobe \
--exclude usr/lib/apache2 \
--exclude usr/lib/calibre \
--exclude usr/lib/chromium \
--exclude usr/lib/cups \
--exclude usr/lib/debug \
--exclude usr/lib/dri \
--exclude usr/lib/gcc \
--exclude usr/lib/gconv \
--exclude usr/lib/git-core \
--exclude usr/lib/goffice \
--exclude usr/lib/googleearth \
--exclude usr/lib/i386-linux-gnu \
--exclude usr/lib/isdn \
--exclude usr/lib/jvm \
--exclude usr/lib/kde4 \
--exclude usr/lib/lapack \
--exclude usr/lib/libreoffice  \
--exclude usr/lib/libvirt \
--exclude usr/lib/p7zip \
--exclude usr/lib/ruby \
--exclude usr/lib/scons \
--exclude usr/lib/vlc \
--exclude usr/lib/wine \
--exclude usr/lib/X11 \
--exclude usr/lib/xorg \
--exclude usr/lib/openoffice \
usr/lib

# locale

crunch usr.share \
$(exclude 'fonts*') \
--exclude doc \
--exclude foomatic \
--exclude gnome \
--exclude gnome-applets \
--exclude icons \
--exclude man \
--exclude pixmaps \
--exclude selinux \
--exclude X11 \
usr/share

# crunch usr.share.locale.en_US usr/share/locale/en_US/

# if [ -e /usr/share/fonts/default ]\
#   && [ -e /usr/share/fonts/ISO8859-2 ]\
#   && [ -e /usr/share/fonts/bitmap-fonts ]; then
#     crunch usr.share.fonts /usr/share/fonts/default /usr/share/fonts/ISO8859-2 \
#     /usr/share/fonts/bitmap-fonts
# fi

crunch root --exclude root/tmp --exclude root/.cpan --exclude root/.mozilla --exclude root/down root
crunch boot boot
crunch etc --exclude etc/samba --exclude etc/gconf etc #  --exclude etc/X11
if [ -e lib64 ] ; then
    crunch lib64 lib64
fi
crunch lib lib

crunch usr.sbin usr/sbin
# crunch usr.local usr/local
# crunch usr.libexec usr/libexec

if [ $REDHAT == 0 ] ; then
  crunch usr.kerberos usr/kerberos
fi

crunch usr.bin --exclude usr/bin/emacs-x \
--exclude usr/bin/emacsclient --exclude usr/bin/emacs-nox --exclude \
usr/bin/gs --exclude usr/bin/pine $(exclude 'usr/bin/gimp-*') \
--exclude usr/bin/doxygen --exclude usr/bin/postgres --exclude \
usr/bin/gdb --exclude usr/bin/kmail --exclude usr/bin/splint \
--exclude usr/bin/odbctest --exclude usr/bin/php --exclude \
usr/bin/xchat --exclude usr/bin/gnucash --exclude usr/bin/pdfetex \
--exclude usr/bin/pdftex --exclude usr/bin/smbcacls \
--exclude usr/bin/evolution-calendar --exclude usr/bin/xpdf \
--exclude usr/bin/xmms usr/bin

crunch sbin sbin
crunch bin bin
crunch dev dev
crunch run run

# Debian amanda clients will want these in order to run amrecover:
crunch var.backup var/backups
crunch var.log.amanda var/log/amanda
crunch var.lib.amanda var/lib/amanda
# How well will this work if you don't run this script after every
# backup? I suspect these will get out of synch with the amanda
# backups.

# End amanda on Debian


# RH8. Fedora 1 puts them in /lib
# crunch kerberos usr/kerberos/lib/

# Now optional saves.

# arkeia specific:
# crunch arkeia usr/knox

# save these so we can use ssh for restore. *crack* for RH 7.0 login
# authentication.
# RH 8.0
# crunch usr.lib usr/lib/*crack* usr/lib/libz* usr/lib/libssl* usr/lib/libcrypto*
# Fedora 1
# crunch usr.lib usr/lib/*crack* usr/lib/libz* usr/lib/libwrap*\
#  usr/lib/libk* usr/lib/*krb5* /usr/lib/libgss*
# Fedora 3
# crunch usr.lib usr/lib/*crack* usr/lib/libz* usr/lib/libwrap*\
#  usr/lib/libk* usr/lib/*krb5* usr/lib/libgss*
# Fedora 7
# crunch usr.lib usr/lib/*crack*\
#  usr/lib/libk* usr/lib/*krb5* usr/lib/libgss*

# Grub requires these at installation time.
if [ $REDHAT == 0 ] ; then
  crunch usr.share.grub usr/share/grub
else
  crunch usr.lib.grub usr/lib/grub
fi

# save the scripts we will use to restore.
cp -p /etc/bare.metal.recovery/* ${zip}/bin

echo "Testing our results."
find ${zip} -iname "*.bz2" | xargs bunzip2 -t

# Since we're doing system stuff anyway, make a boot disk ISO image
# suitable for burning. It uses the current kernel.

if [ $REDHAT == 0 ] ; then
  mkbootdisk --iso --device ${zip}/bootdisk.$(uname -r).iso $(uname -r)
fi

# Recent kernels have incorporated a new ATA (IDE) hard drive
# driver. Because of this, parallel ATA drives now show up as SCSI
# drives, as serial ATA have always done. However, not all rescue
# distributions (e.g. finix) use this new driver. So the following
# line very carefully replaces "/dev/sda" with "/dev/hda". Use this as
# a template if you have multiple IDE hard drives.

# Note that there is no guaranteed mapping! Systems with multiple hard
# drives may have confusing mappings. Be sure to edit this line
# carefully. Check it if you add or remove a hard drive of any
# interface type to or from your system!

find ${zip} -type f | grep -v bz2$ | xargs sed -i 's|/dev/sda|/dev/hda|g'

du -hs ${zip}
df -h

#! /usr/bin/perl

# A perl script to create a script and input file for fdisk to
# re-create the partitions on the hard disk, and format the Linux and
# Linux swap partitions. The first parameter is the fully qualified
# path of the device of the hard disk, e.g. /dev/hda. The two
# resulting files are the script make.dev.x and the data file dev.x
# (where x is the hard drive described, e.g. hda, sdc). make.dev.x is
# run at restore time to rebuild hard drive x, prior to running
# restore.metadata. dev.x is the input file for fdisk.

# The directory tree where everything is put must already exist and be
# specified in the environment variable $zip.

# Copyright 2001 through the last date of modification Charles Curley
# except for the subroutine cut2fmt.

# cut2fmt Copyright (c) 1998 Tom Christiansen, Nathan Torkington and
# O'Reilly & Associates, Inc.  Permission is granted to use this code
# freely EXCEPT for book publication.  You may use this code for book
# publication only with the explicit permission of O'Reilly &
# Associates, Inc.

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

# In addition, as a special exception, Tom Christiansen, Nathan
# Torkington and O'Reilly & Associates, Inc.  give permission to use
# the code of this program with the subroutine cut2fmt (or with
# modified versions of the subroutine cut2fmt that use the same
# license as the subroutine cut2fmt), and distribute linked
# combinations including the two.  You must obey the GNU General
# Public License in all respects for all of the code used other than
# the subroutine cut2fmt.  If you modify this file, you may extend
# this exception to your version of the file, but you are not
# obligated to do so.  If you do not wish to do so, delete this
# exception statement and the subroutine cut2fmt from your version.

# You can also contact the Free Software Foundation at
# http://www.fsf.org/

# Changes:

# 2017-07-16: Some disties (Debian 8,9; jessie,stretch), have
# lvm2. Test for it & use it if it's there.

# 2011-09-07: Per email from Michael Coffman: getextopts was leaving
# the "needs_recovery" flag in the ext? options, and mke2fs throws up
# on it. Added a line to remove it.

# 2010-03-22: We now use dumpe2fs to recover ext[3|4] partitions'
# features and use the -O option to mke2fs. So custom partitions' file
# systems will be laid down correctly.

# 2010-03-20: Improved handling of ext4. (There's more to do.) Fixed a
# bug with line endings in the output of "mount -l".

# 2010-01-12: An even better way to get UUIDs, which simplified the
# code and removed a bug, a false return if there was no UUID.

# 2009-12-24: Found a better way to get UUIDs. So we now provide them
# for swap partitions.

# 2007-11-05: Preserve UUIDs (Ubuntu). There is no way to set a UUID
# on a swap partition, so we punt: fix them up manually after the
# fact. The easiest fix is for you to edit fstab to refer to swap
# partitions by device name. Alternatively, see
# https://bugs.launchpad.net/ubuntu/+source/util-linux/+bug/66637,
# http://www.thinkwiki.org/wiki/Installing_Ubuntu_7.04_on_a_ThinkPad_T43#Swap_and_Hibernation_problem
# and
# https://bugs.launchpad.net/ubuntu/+source/util-linux/+bug/66637/comments/23
# et seq. for a list of things to do. Gnrrr.

# 2007-06-10: In addition to scanning /etc/fstab for LVM partitions
# (logical volumes), we also check the device files in /dev. This is
# because some logical volumes may be mounted by label, and scanning
# fstab won't pick those up.

# 2007-05-22: Changes for FHS compliance. Removed commented out
# references to ZIP drives. N.B.: we now take the location of where to
# put things as an environment variable, $zip.

# 2006-04-15: Added support for partition type 0x12, "Compaq
# diagnostic". This type is used for so-called "hidden diagnostics"
# partitions, e.g. on Lenovo/IBM computers.

# 2006-04-08: Primitive LVM support. It is kludgy in that it uses
# first stage restoration distribution (finnix) specific code to turn
# LVM on and off, but otherwise seems to work.

# 2006-03-28: We have a problem if swap partitions have
# labels. There's no way to retrieve the label from a swap
# partition. If we have one & only one swap partition, then we can
# pull it out of /etc/fstab. Otherwise the user is on her own. We scan
# fstab for swap mount points that have labels for their devices. If
# there is one and only one, we assume that's it, otherwise pass.

# 2005-10-29: We now provide the geometry as an argument to fdisk
# (which does not work on tomsrtbt). We also save data for sfdisk, and
# write out make.dev.xxx so that it will use sfdisk if it finds it.

# 2005-08-14: Due to experience on Knoppix, we now add the code to
# change the partition types to the end of the fdisk input file
# instead of right after creating the partition.

# 2004 04 10: fdisk v > 2.11 has wider columns. Added code to select
# the appropriate cut string based on fdisk's version.

# 2004 04 09: Added support for Mandrake's idea of devfs. On Mandrake,
# everything is mounted with devfs. So the mount devices are buried
# deep in places like /dev/ide/host0/bus0/target0/lun0/part1 instead
# of places like /dev/hda1, where $DEITY intended they should be. We
# have to reverse from the long devfs device to the shorter old style
# that tomsrtbt uses. The alternative is to keep track in an array of
# which devfs device belongs to which short device.

# 2003 12 29: Changed the regex for detecting whether a file system is
# read-write in the code that builds the mount file(s). The old test
# does not work if mount returns multiple parameters in the 5th field,
# e.g. (rw,errors=remount-ro) on some debian systems. This regex
# assumes that the rw parameter is always listed first, which may not
# always be the case. If it fails, take out the '\('. Thanks to Pasi
# Oja-Nisula <pon at iki dot fi> for pointing this out.

# 2003 01 09: Added support for FAT32. We now create two scripts for
# each hard drive, make.dev.[as]dx and mount.dev.[as]dx. These create
# and make file systems on each partition, and make mount points and
# mount them.

# 2002 12 25: added support to handle W95 extended (LBA) (f) and W95
# FAT 32 partitions. I have tested this for primary but not logical
# partitions.

# 2002 09 08: Added minimal support for ext3fs. We now detect mounted
# ext3fs partitions & rebuild but with no options. The detection
# depends on the command line "dumpe2fs <device> 2>/dev/null | grep -i
# journal" producing no output for an ext2fs, and output (we don't
# care what) for an ext3fs.

# This could stand extension to support non-default ext3 options such
# as the type of journaling. Volunteers?

# 2002 07 25: Bad block checking is now a command line option (-c) at
# the time the product script is run.

# 2002 07 03: Corrected the mechanism for specifying the default
# drive.

# 2001 11 25: Changed the way mke2fs gets its bad block
# list. badblocks does not guess at the block size, so you have to get
# it (from dumpe2fs) and feed it to badblocks. It is simpler to just
# have mke2fs call badblocks, but you do loose the ability to have a
# writing test easily. -- C^2

# 2001 11 25: Changed the regex that extracts partition labels from
# the mount command. This change does not affect the results at all,
# it just makes it possible to use Emacs' perl mode to indent
# correctly. I just escaped the left bracket in the regex. -- C^2

# Discussion:

# fdisk will spit out a file of the form below if you run it as "fdisk
# -l".

# root@tester ~/bin $ fdisk -l /dev/hda

# Disk /dev/hda: 64 heads, 63 sectors, 1023 cylinders
# Units = cylinders of 4032 * 512 bytes

#    Device Boot    Start       End    Blocks   Id  System
# /dev/hda1             1         9     18112+  83  Linux
# /dev/hda2            10      1023   2044224    5  Extended
# /dev/hda5            10       368    723712+  83  Linux
# /dev/hda6           369       727    723712+  83  Linux
# /dev/hda7           728       858    264064+  83  Linux
# /dev/hda8           859       989    264064+  83  Linux
# /dev/hda9           990      1022     66496+  82  Linux swap

# What fdisk does not do is provide output suitable for later
# importing into fdisk, a la sfdisk. This script parses the output
# from fdisk and creates an input file for fdisk. Use the input file
# like so:

# fdisk /dev/hdx < dev.hdx

# For the bare metal restore package, this script also builds a script
# that will execute the above command so you can run it from your zip
# disk. Because the bare metal restore scripts all are in /root/bin,
# the data file and script created by this script are also placed
# there. The same script also creates appropriate Linux file systems,
# either ext2fs, or Linux swap. There is limited support for FAT12,
# FAT16 and FAT32. For anything else, you're on your own.

# Note for FAT32: According to the MS KB, there are more than one
# reserved sectors for FAT32, usually 32, but it can vary. Do a search
# in M$'s KB for "boot sector" or BPB for the gory details. For more
# info than you really need on how boot sectors are used, see
# http://support.microsoft.com/support/kb/articles/Q140/4/18.asp

# You can also edit dev.x to change the sizes of partitions. Don't
# forget, if you change the size of a FAT partition across the 32MB
# boundary, you need to change the type as well! Run "fdisk /dev/hda"
# or some such, then the l command to see the available partition
# types. Then go ahead and edit dev.x appropriately. Also, when moving
# partition boundarys with hand edits, make sure you move both logical
# and extended partition boundaries appropriately.

# Bad block checking right now is a quick read of the partition. A
# writing check is also possible but more difficult. You have to run
# badblocks as a separate command, and pass the bad block list to
# mke2fs in a file (in /tmp, which is a ram disk). You also have to
# know how large the blocks are, which you learn by running
# dumpe2fs. It gets messy and I haven't done it yet. You probably
# don't need it for a new hard drive, but if you have had a hard drive
# crash on you and you are reusing it (while you are waiting for its
# replacement to come in, I presume), then I highly recommend it. Let
# me know how you do it.

# For more information contact the author, Charles Curley, at
# http://www.charlescurley.com/.

use UUID;			# for validating uuids.

# cut2fmt figures out the format string for the unpack function we use
# to slice and dice the output from fdisk. From Christiansen and
# Torkington, Perl Cookbook 5.

sub cut2fmt {
    my (@positions) = @_;
    my $template    = '';
    my $lastpos     = 1;

    foreach $place (@positions) {
        $template .= "A" . ($place - $lastpos) . " ";
        $lastpos = $place;
    }

    $template .= "A*";
    return $template;
}


# Sub gpl, a subroutine to ship the GPL and other header information
# to the current output file.

sub gpl {
    my $FILE = shift;
    my $year = shift;

    print $FILE <<FINIS;

# Copyright $year through the last date of modification Charles Curley.

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

FINIS

}

sub getBootSector {
    my $infile = $_[0];
    my $outfile = $_[1];

    $systemcmd = "dd if=$infile of=$outfile bs=512 count=1 &> /dev/null ";
    system ($systemcmd);
}


# If we have one & only one swap partition, then this must be
# it. Otherwise the user is on her own. We scan fstab for swap mount
# points that have labels for their devices. If there is one and only
# one, we assume that's it, otherwise pass.

sub getswaplabel {
    my $dev = $_[0];

    open (FSTAB, "< /etc/fstab")
        or die "Couldn't fork: $!\n";
    while (defined (my $line = <FSTAB>)) {
        chop ($line);
        @fstabs = split (" ", $line);
        if (@fstabs[1] eq "swap") {
            $swaplabel = @fstabs[0];
            if ($swaplabel =~ /LABEL/) {
                $swaps++;
                $sl = substr ($swaplabel, 6);
            }
#           print ("\"@fstabs[0]\", \"@fstabs[1]\", \"$sl\", $swaps.\n");
            break;
        }
    }
    close (FSTAB);

#   print "label is $sl.\n";

    if ($swaps == 1) {
        $ret = "-L $sl $dev\n";
    } else {
        $ret = "$dev\n";
    }

#   print ("Returning :$ret\n");

    return $ret;
}

# dolvm is a subroutine to handle LVM partitions.

$lvms = 0;          # true if we've been here before

sub dolvm {

#     print ("In dolvm ()...\n");

    if ($lvms == 0) {
        $lvms = 1;

        # Scan /etc/fstab for the logical volumes and write a script to
        # make file systems on them and another to mount 'em later on.

        $mklvs = open (MKLVS, "> ${outputfilepath}bin/make.lvs")
            or die "Couldn't fork: $!\n";

        print MKLVS <<FINIS;
#! /bin/sh

# A script to create file systems on logical volumes. Created at bare
# metal backup time by the Perl script make.fdisk.
FINIS

        &gpl (*MKLVS, "2006");


        print MKLVS <<FINIS;

export blockcheck=\$1;

if [ "\$blockcheck" != "-c" ] && [ -n "\$blockcheck" ]
then
    echo "\${0}: Build file systems on logical volumes."
    echo "\${0}: -c: block check during file system making."
    exit 1;
fi

FINIS

        $mtlvs = open (MTLVS, "> ${outputfilepath}bin/mount.lvs")
            or die "Couldn't fork: $!\n";

        print MTLVS <<FINIS;
#! /bin/sh

# A script to mount file systems on logical volumes. Created at bare
# metal backup time by the Perl script make.fdisk.
FINIS

        &gpl (*MTLVS, "2007");


        # Now cycle through all the known logical volumes & set them
        # up. N.B.: This has been tested on machines with only one LV
        # and with two. It picks up both on that test machine.

        $pvdisp = open (PVDISP, "pvdisplay -c |")
            or die ("Can't open LVM display.\n");
        while (defined (my $pv = <PVDISP>)) {
            chop ($pv);
#             print ("$pv\n");
            @pv = split (":", $pv);
            $uid = @pv[11];
            $pvname = @pv[1];
            $phv = @pv[0];
#             print ("pv $pvname has uid $uid.\n");

            # back up the LVM's lvm details. Get the config files.
            system ("vgcfgbackup -f ${outputfilepath}metadata/LVM.backs.$pvname $pvname");

            print (MKLVS "echo \"y\\n\" | pvcreate -ff --uuid \"$uid\"\\\n");
            print (MKLVS "    --restorefile ../metadata/lvm/backup/${pvname} $phv\n");
            print (MKLVS "vgcfgrestore --file ../metadata/LVM.backs.$pvname $pvname\n\n");
        }

        print (MKLVS "# Hideously disty dependent! turn on LVM.\n");
        print (MKLVS "if [ -e /etc/init.d/lvm ] ; then\n");
        print (MKLVS "    /etc/init.d/lvm start\nfi\n\n");
        print (MKLVS "if [ -e /etc/init.d/lvm2 ] ; then\n");
        print (MKLVS "    /etc/init.d/lvm2 start\nfi\n\n");

        # Now walk fstab in search of logical volumes. This is
        # necessary to pick up swap partitions, and it may pick up
        # others. We need fstab below to match the partitions up with
        # their mount points, so we keep the array around.

        %volsfound = ();
        open (FSTAB, "< /etc/fstab")
            or die "Couldn't fork: $!\n";
        @fstab = <FSTAB>;
        foreach $line (@fstab) {
            @fstabs = split (" ", $line);
            #                   Red Hat|Ubuntu
            if (@fstabs[0] =~ /VolGroup|mapper/ ) {
                # print ("$line");
                if (@fstabs[2] eq "swap") {
                    print (MKLVS "echo\necho making LV @fstabs[0] a swap partition.\n");
                    print (MKLVS "mkswap \$blockcheck @fstabs[0]\n\n");
                } elsif (@fstabs[2] == "ext4") {
                    print (MKLVS "echo\necho making LV @fstabs[0], @fstabs[1],");
                    print (MKLVS " an ext4 partition.\n");
                    print (MKLVS "mke2fs -t ext4" . getextopts (@fstabs[0]));
                    print (MKLVS "\$blockcheck @fstabs[0]\n\n");

                    print (MTLVS "mkdir -p /target$fstabs[1]\n");
                    print (MTLVS "mount @fstabs[0] /target$fstabs[1]\n\n");
                    $volsfound{@fstabs[0]} = 4;
                } elsif (@fstabs[2] == "ext3") {
                    print (MKLVS "echo\necho making LV @fstabs[0], @fstabs[1],");
                    print (MKLVS " an ext3 partition.\n");
                    print (MKLVS "mke2fs -t ext3" . getextopts (@fstabs[0]));
                    print (MKLVS "\$blockcheck @fstabs[0]\n\n");

                    print (MTLVS "mkdir -p /target$fstabs[1]\n");
                    print (MTLVS "mount @fstabs[0] /target$fstabs[1]\n\n");
                    $volsfound{@fstabs[0]} = 3;
                } elsif (@fstabs[2] == "ext2") {
                    print (MKLVS "echo\necho making LV @fstabs[0], @fstabs[1],");
                    print (MKLVS " an ext2 partition.\n");
                    print (MKLVS "mke2fs \$blockcheck @fstabs[0]\n\n");

                    print (MTLVS "mkdir -p /target$fstabs[1]\n");
                    print (MTLVS "mount @fstabs[0] /target$fstabs[1]\n\n");
                    $volsfound{@fstabs[0]} = 2;
                } else {
                    print ("Opps, unknown type of logical volume, @fstabs[0]\n");
                }
            }
        }

#         print ("Volumes already found are: ");
#         while ( ($k, $v) = each %volsfound ) {
#             print ("$k ==> $v ");
#         }
#         print ("\n");

        # Now walk the logical volume devices and pick up any
        # partitions formated ext3/ext2. This may result in duplicates
        # if the partitions have labels but are mounted by device name
        # rather than by label.

        # FIX ME: This loop doesn't distinguish between ext3 and
        # ext4. It may not need to, as we pull the options from the
        # partition itself. If so, that would be nice.

        opendir (DEVHANDLE, "/dev") or die ("Can't open /dev!!\n");
        while ( defined ($fname = readdir (DEVHANDLE))) {
            @fnames = (@fnames, $fname);
        }
        @sorted = sort (@fnames);
        foreach $fname (@sorted) {
            #                Red Hat|Ubuntu
            if ($fname =~ /^VolGroup|^mapper/ && -d "/dev/$fname") {
                # print ("Inside /dev is $fname.\n");
                opendir (VOLHANDLE, "/dev/$fname")
                    or die ("Can't open /dev/$fname!!\n");
                while ( defined ($vname = readdir (VOLHANDLE))) {
                    @vnames = (@vnames, $vname);
                }
                @vsorted = sort (@vnames);
                foreach $vname (@vsorted) {
#                     print "/dev/$fname/$vname: " . $volsfound{"/dev/$fname/$vname"} . "\n";
                    if($vname ne "." && $vname ne ".."
                       && $volsfound{"/dev/$fname/$vname"} < 1) {
#                         print ("Inside /dev/$fname is $vname.\n");
                        my $journal = 0;

                        # FIX ME: add tests to be sure it's a symlink
                        # to a block device.

                        # Is it extX?
                        open (DUMP, "dumpe2fs /dev/$fname/$vname 2> /dev/null|");

                        @lines = <DUMP>;

                        if (scalar (@lines) > 1) {

                            # If we've gotten here we have a valid
                            # ext[2|3|4] file system. Now prepare to
                            # spit out the commands to recreate
                            # it. Get the label, if any, and whether
                            # there is a journal or not.

                            foreach $_ (@lines) {
                                if (/Filesystem volume name:/) {
                                    $label = substr ($_, 26);
                                    chop ($label);
#                                     print ("\$label is \"$label\".\n");
                                }
                                if (/has_journal/) {
                                    $journal = 1;
                                }

                            }

                            # get the mount point from fstab so we can mount it.
                            $mountpoint = "none!";
                            foreach $fstab (@fstab) {
                                @fstabs = split (" ", $line);
                                if (@fstabs[0] eq "LABEL=$label" ) {
                                    $mountpoint = @fstabs[1];
#                                     print ("mount point is \"$mountpoint\".\n");
                                    last;
                                }
                            }
                            if (length ($label) ) {
                                $label = "-L \"" . $label . "\"";
                            }

                            if ($journal > 0) {
                                print (MKLVS "echo\necho making LV /dev/$fname/$vname");
                                print (MKLVS " an ext3/4 partition.\n");
                                print (MKLVS "mke2fs" . getextopts ("/dev/$fname/$vname"));
                                print (MKLVS "$label \$blockcheck /dev/$fname/$vname\n\n");

                                if ($mountpoint ne "none!") {
                                  print (MTLVS "mkdir -p /target$mountpoint\n");
                                  print (MTLVS "mount /dev/$fname/$vname /target$mountpoint\n\n");
                                }
                              } else {
                                print (MKLVS "echo\necho making LV /dev/$fname/$vname");
                                print (MKLVS " an ext2 partition.\n");
                                print (MKLVS "mke2fs $label \$blockcheck /dev/$fname/$vname\n\n");

                                if ($mountpoint ne "none!") {
                                  print (MTLVS "mkdir -p /target$mountpoint\n");
                                  print (MTLVS "mount /dev/$fname/$vname /target$mountpoint\n\n");
                                }
                              }
                        }
                    }

                }
                closedir (VOLHANDLE);
            }
        }
        print (MTLVS "mount | grep -i \"/target\"\n");

        closedir (DEVHANDLE);

        close (FSTAB);
        close (MKLVS);
        close (MTLVS);

        chmod 0700, "${outputfilepath}bin/make.lvs";
        chmod 0700, "${outputfilepath}bin/mount.lvs";

        # Copy the LVM configuration to where we can get at it...
        system ("cp -rp /etc/lvm ${outputfilepath}metadata/");

    }

#     print ("Leaving dolvm ()...\n");

    return ($ret);
}

sub getuuid {
    my $device = shift;

    # print ("In getuuid. \$device = $device.\n");

    my $rs = open (UUID, "blkid -o value -s UUID $device |")
        or die ("Can't open volume id tool.\n");
    while (defined (my $uuid = <UUID>)) {
        chop ($uuid);
        # print ("$uuid\n");

	if (UUID::parse($uuid, my $rawUuid) != -1) {
	    # print ("Device $device has uuid '$uuid'.\n");
	    return ($uuid);
	}
    }
    return ('');
}

# scan the partition for the options to mke2fs.

sub getextopts {
  my $device = $_[0];
  # print ("Device is $device\n");

  open (DUMP, "dumpe2fs $device 2> /dev/null|") or
    die ("Can't open a dump.\n");

  my @lines = <DUMP>;
  if (scalar (@lines) > 1) {

    foreach $_ (@lines) {
      # print ("line: $_");

      if (/Filesystem features/) {
        $_ = substr ($_, 26);
        chop ();
        $_ =~ s/needs_recovery //g;
        $_ =~ s/ /,/g;
        # print ("Features are: ${_}.\n");
        return ($_ = ' -O ' . $_ . ' ');
      }
    }
    die ("Couldn't get features from device $device\n");
  } else {
    die ("Couldn't run dumpe2fs on $device.\n");
  }
}

# Begin main line code.

# $outputfilepath = "/root/bin/";
$outputfilepath = $ENV{"zip"} . "/";
if ($outputfilepath eq "/") {
    $outputfilepath =  "./";
}
# print "\$outputfilepath is ${outputfilepath}\n";

# These will "fail" silently if the directory is already there, which
# it should be if we're called from save.metadata. These simplify
# testing, though.

mkdir ("${outputfilepath}metadata", 0700);
mkdir ("${outputfilepath}bin", 0700);

# Provide a default device.

# print "\$ARGV[0] is $ARGV[0].\n";

$device = defined ($ARGV[0]) ? $ARGV[0] : "/dev/hda";

# Need to check to see if $device is a sym link. If it is, the mount
# point is the target of the link. (Mandrake) Otherwise we search for
# mount points on $device. Fedora, Red Hat.

if ( -l $device) {

    # It is a sym link. Get the target of the link, then make it into
    # an absolute path, preserving the numbering.

    $mountdev = '/dev/' . readlink ($device);
    $mountdev =~ s|ide/host(\d+)/bus(\d+)/target(\d+)/lun(\d+)/disc
        |ide/host\1/bus\2/target\3/lun\4|x;
} else {
    # not a sym link; just assign it.
    $mountdev = $device;
}

# print "Device is $device; mount device is $mountdev.\n";

# Prepare format string. Here are two format strings I have found
# useful. Here, column numbers are 1 based, i.e. the leftmost column
# is column 1, not column 0 as in Emacs.

# We select a format string according to fdisk's version.

$fdpid = open (FDVER, "fdisk -v |") or die "Couldn't fork: $!\n";
while (<FDVER>) {
    @_ = unpack ("A7 A*", $_);
    $fdver=$_[1];
    $fdver =~ s/[^\d.]//g; # strip non-numbers, non-periods, as in "2.12pre".
}

# print "fdisk version is $fdver\n";

if ($fdver < 2.12) {
# fdisk to 2.11?? Red Hat, Fedora Core 1
    $fmt = cut2fmt (11, 19, 24, 34, 45, 49);
} else {
# fdisk 2.12 & up?? Mandrake 10.0, Fedora Core 2
    $fmt = cut2fmt (12, 14, 26, 38, 50, 55);
}
# print "Format string is $fmt.\n";

# define fields in the array @_.
$dev = 0;
$bootable = 1;
$firstcyl = 2;
$lastcyl = 3;
$parttype = 5;
$partstring = 6;

$target = "\/target";

$outputfilename = $device;
$outputfilename =~ s/\//./g;
$outputfilename = substr ($outputfilename, 1, 100);

# Make a hash of the labels.
$mpid = open (MOUNT, "mount -l |") or die "Couldn't fork: $!\n";
while (<MOUNT>) {
    if ($_ =~ /^$mountdev/i) { # is this a line with a partition in it?
        chop;
        # print "mount line is \"$_\"\n"; # print it just for grins
        split;
        if ($_[6] ne "") {      # only process if there actually is a label
            $_[6] =~ s/[\[\]]//g; # strike [ and ].
            $labels{$_[0]} = $_[6];
#           print "The label of file device $_[0] is $labels{$_[0]}.\n";
        }


        # We only mount if it's ext2fs, ext3fs, or ext4fs, and read
        # and write.

        if ($_[4] =~ /ext[234]/ and $_[5] =~ /\(rw/ ) {
            if ($_[0] =~ /ide/i) {

                # We have a devfs system, e.g. Mandrake. This code
                # converts back from the devfs designation to the old
                # /dev/hd* designation for tomsrtb. I have NOT checked
                # this out for drives other than /dev/hda. Also, this
                # code does not handle SCSI drives.

                if ( $_[0] =~ /target0/ && $_[0] =~ /bus0/ ) {
                    $letter = 'a';
                } elsif ( $_[0] =~ /target1/ && $_[0] =~ /bus0/) {
                    $letter = 'b';
                } elsif ( $_[0] =~ /target0/ && $_[0] =~ /bus1/) {
                    $letter = 'c';
                } else {
                    $letter = 'd';
                }
                $_[0] =~ s|/ide/host\d+/bus\d+/target\d+/lun\d+/part|/hd|g;
                $_[0] =~ s/hd/hd$letter/;
            }
            $mountpoints{$_[2]} = $_[0];
            # print "$_[2] is the mountpoint for tomsrtbt|finnix";
            # print " device $mountpoints{$_[2]}.\n";
        }
    }
}
close (MOUNT);

# Get sfdisk output. If we have sfdisk at restore time (e.g. Knoppix),
# we'll use it.

system "sfdisk -d $device > ${outputfilepath}metadata/${outputfilename}.sfd";

# Otherwise we'll use the output from fdisk, which may or may not be
# any more accurate.

$fpid = open (FDISK, "fdisk -l $device |") or die "Couldn't fork: $!\n";

open (OUTPUT, "> ${outputfilepath}metadata/${outputfilename}")
    or die "Couldn't open output file ${outputfilepath}metadata/${outputfilename}.\n";

while (<FDISK>) {
    if ($_ =~ /^$device/i) {    # is this a line with a partition in it?
#       print $_;               # print it just for grins
        chop;                   # kill trailing \r
        @_ = unpack ($fmt, $_);

        # Now strip white spaces from cylinder numbers, white space &
        # leading plus signs from partition type.
        @_[$firstcyl] =~ s/[ \t]+//;
        @_[$lastcyl] =~ s/[ \t]+//;
        @_[$parttype] =~ s/[+ \t]+//;

        $partnumber = substr(@_[$dev], 8, 10); # get partition number for this line
        # just for grins
#         print "  $partnumber, @_[$firstcyl], @_[$lastcyl],";
#         print " @_[$parttype], @_[$partstring]\n";

        # Here we start creating the input to recreate the partition
        # this line represents.

        print OUTPUT "n\n";
        if ($partnumber < 5) {
            # primary Linux partition
            if (@_[$parttype] == 83) {
                print OUTPUT "p\n$partnumber\n@_[$firstcyl]\n";
                # in case it's all on one cylinder
                if (@_[$firstcyl] ne @_[$lastcyl]) {
                    print OUTPUT "@_[$lastcyl]\n";
                }

#                 # Now detect if this is an ext3 (journaling)
#                 # partition. We do this using dumpe2fs to dump the
#                 # partition and grepping on "journal". If the
#                 # partition is ext2, there will be no output. If it is
#                 # ext3, there will be output, and we use that fact to
#                 # set a command line switch. The command line switch
#                 # goes into an associative array (hash) so we don't
#                 # have to remember to reset it to the null string when
#                 # we're done.

#                 $dpid = open (DUMPE2FS,
#                               "dumpe2fs @_[$dev] 2>/dev/null | grep -i journal |")
#                     or die "Couldn't fork: $!\n";
#                 while (<DUMPE2FS>) {
# #                   print "Dumpe2fs: $_";
#                     $ext3{$_[$dev]} = "-j ";
#                     last;
#                 }
#                 close (DUMPE2FS);

                if ($labels{@_[$dev]}) { # do we have a label?
                    $format .= "echo\necho formatting $checking@_[$dev]\n";
                    # $format .= "mke2fs $ext3{$_[$dev]}\$blockcheck";
                    # $format .= " -L $labels{@_[$dev]} @_[$dev]\n";
                    $format .= "mke2fs" . getextopts ($_[$dev]) . "\$blockcheck";
                    $format .= " -L $labels{@_[$dev]} @_[$dev]\n";
                } else {
                    $format .= "echo\necho formatting $checking@_[$dev]\n";
                    # $format .= "mke2fs $ext3{$_[$dev]}\$blockcheck @_[$dev]\n";
                    $format .= "mke2fs" . getextopts ($_[$dev]) . "\$blockcheck @_[$dev]\n";
                }
                $uuid = getuuid ($_[$dev]);
                if (length ($uuid) > 0) {
                    $format .= "tune2fs -U $uuid @_[$dev]\n";
                }

                $format .= "\n";

                # extended partition
            } elsif (@_[$parttype] == 5) {
                # print ("Creating Extended Partition.\n");
                print OUTPUT "e\n$partnumber\n@_[$firstcyl]\n";
                if (@_[$firstcyl] ne @_[$lastcyl]) {
                    print OUTPUT "@_[$lastcyl]\n";
                }

                # extended partition, Win95 Ext'd (LBA)
            } elsif (@_[$parttype] eq "f") {
                # print ("Creating Extended LBA Partition.\n");
                print OUTPUT "e\n$partnumber\n@_[$firstcyl]\n";
                if (@_[$firstcyl] ne @_[$lastcyl]) {
                    print OUTPUT "@_[$lastcyl]\n";
                }
                $typechanges .= "t\n$partnumber\nf\n";

                # primary Linux swap partition
            } elsif (@_[$parttype] == 82) {
                print OUTPUT "p\n$partnumber\n@_[$firstcyl]\n";
                if (@_[$firstcyl] ne @_[$lastcyl]) {
                    print OUTPUT "@_[$lastcyl]\n";
                }
                $typechanges .= "t\n$partnumber\n82\n";
                $format .= "echo\necho Making @_[$dev] a swap partition.\n";
		$format .= "mkswap \$blockcheck ";
                $uuid = getuuid ($_[$dev]);
                if (length ($uuid) > 0) {
		    $format .= "-U $uuid ";
                }
                if ($labels{@_[$dev]}) { # do we have a label?
                    $format .= "-L $labels{@_[$dev]} ";
                    $format .= "@_[$dev]\n";
                } else {
                    $format .= getswaplabel (@_[$dev]);
                }

                $format .= "\n";

                # Primary mess-dos partition. We don't handle hidden
                # partitions.

            } elsif ( @_[$parttype] == 1 || @_[$parttype] == 4 || @_[$parttype] == 6
                      || @_[$parttype] eq "b" || @_[$parttype] eq "c"
                      || @_[$parttype] eq "e" || @_[$parttype] eq "12" ) {
                # print ("Making DOS primary partition.\n");

                getBootSector (@_[$dev], "${outputfilepath}metadata/$outputfilename$partnumber");

                print OUTPUT "p\n$partnumber\n@_[$firstcyl]\n";
                # in case it's all on one cylinder
                if (@_[$firstcyl] ne @_[$lastcyl]) {
                    print OUTPUT "@_[$lastcyl]\n";
                }

                $typechanges .= "t\n$partnumber\n@_[$parttype]\n";
                $format .= "echo\necho formatting $checking@_[$dev]\n";
                $format .= "mkdosfs \$blockcheck";
                if ( @_[$parttype] == b || @_[$parttype] == c
                     || @_[$parttype] eq "12" ) {
                    # We have a W9x FAT32 partition. Add a command line switch.
                    $format .= " -F 32";
                }
                $format .= " @_[$dev]\n";
                $format .= "# restore FAT boot sector.\n";
                $format .= "dd if=$outputfilename$partnumber";
                $format .= " of=@_[$dev] bs=512 count=1\n\n";

            } elsif ( @_[$parttype] == "8e") {
                $format .= dolvm ();
            } else {
                # anything else partition
                print OUTPUT "p\n@_[$firstcyl]\n";
                if (@_[$firstcyl] ne @_[$lastcyl]) {
                    print OUTPUT "@_[$lastcyl]\n";
                }
                $typechanges .= "t\n$partnumber\n@_[$parttype]\n";
            }

        } else {
            # logical Linux partition
            if (@_[$parttype] == 83) {
                print OUTPUT "l\n@_[$firstcyl]\n";
                if (@_[$firstcyl] ne @_[$lastcyl]) {
                    print OUTPUT "@_[$lastcyl]\n";
                }

#                 # Now detect if this is an ext3 (journaling)
#                 # partition. We do this using dumpe2fs to dump the
#                 # partition and grepping on "journal". If the
#                 # partition is ext2, there will be no output. If it is
#                 # ext3, there will be output, and we use that fact to
#                 # set a command line switch. The command line switch
#                 # goes into an associative array (hash) so we don't
#                 # have to remember to reset it to the null string when
#                 # we're done.

#                 $dpid = open (DUMPE2FS,
#                               "dumpe2fs @_[$dev] 2>/dev/null | grep -i journal |")
#                     or die "Couldn't fork: $!\n";
#                 while (<DUMPE2FS>) {
# #                   print "Dumpe2fs: $_";
#                     $ext3{$_[$dev]} = "-j ";
#                     last;
#                 }
#                 close (DUMPE2FS);

                if ($labels{@_[$dev]}) { # do we have a label?
                    $format .= "echo\necho formatting $checking@_[$dev]\n";
                    # $format .= "mke2fs $ext3{@_[$dev]}\$blockcheck";
                    # $format .= " -L $labels{@_[$dev]} @_[$dev]\n";
                    $format .= "mke2fs" . getextopts ($_[$dev]) . "\$blockcheck";
                    $format .= " -L $labels{@_[$dev]} @_[$dev]\n";
                } else {
                    $format .= "echo\necho formatting $checking@_[$dev]\n";
                    # $format .= "mke2fs $ext3{@_[$dev]}\$blockcheck @_[$dev]\n";
                    $format .= "mke2fs" . getextopts ($_[$dev]) . "\$blockcheck @_[$dev]\n";
                }
                $uuid = getuuid ($_[$dev]);
                if (length ($uuid) > 0) {
                    $format .= "tune2fs -U $uuid @_[$dev]\n";
                }

                $format .= "\n";

                # logical Linux swap partition
            } elsif (@_[$parttype] == 82 ) {
                print OUTPUT "l\n@_[$firstcyl]\n";
                if (@_[$firstcyl] ne @_[$lastcyl]) {
                    print OUTPUT "@_[$lastcyl]\n";
                }
                $typechanges .= "t\n$partnumber\n82\n";
                $format .= "echo\necho Making @_[$dev] a swap partition.\n";
		$format .= "mkswap \$blockcheck ";
                $uuid = getuuid ($_[$dev]);
                if (length ($uuid) > 0) {
		    $format .= "-U $uuid ";
                }
                if ($labels{@_[$dev]}) { # do we have a label?
                    $format .= "-L $labels{@_[$dev]} ";
                    $format .= "@_[$dev]\n";
                } else {
                    $format .= getswaplabel (@_[$dev]);
                }

                $format .= "\n";

                # Logical mess-dos partition. We don't handle hidden
                # partitions.

            } elsif ( @_[$parttype] == 1 || @_[$parttype] == 4 || @_[$parttype] == 6
                      || @_[$parttype] eq "b" || @_[$parttype] eq "c"
                      || @_[$parttype] eq "e" || @_[$parttype] eq "12" ) {
#               print ("Making DOS logical partition.\n");

                getBootSector (@_[$dev], "${outputfilepath}metadata/$outputfilename$partnumber");

                print OUTPUT "l\n$partnumber\n@_[$firstcyl]\n";
                # in case it's all on one cylinder
                if (@_[$firstcyl] ne @_[$lastcyl]) {
                    print OUTPUT "@_[$lastcyl]\n";
                }
                $typechanges .= "t\n$partnumber\n@_[$parttype]\n";
                $format .= "echo\necho formatting $checking@_[$dev]\n";
                $format .= "mkdosfs \$blockcheck";
                if ( @_[$parttype] == b || @_[$parttype] == c
                     || @_[$parttype] eq "12" ) {
                    # We have a W9x FAT32 partition. Add a command line switch.
                    $format .= " -F 32";
                }
                $format .= " @_[$dev]\n";
                $format .= "# restore FAT boot sector.\n";
                $format .= "dd if=$outputfilename$partnumber";
                $format .= " of=@_[$dev] bs=512 count=1\n\n";

            } elsif ( @_[$parttype] == "8e") {
                $format .= dolvm ();
            } else {
                # anything else partition
                print OUTPUT "l\n@_[$firstcyl]\n";
                if (@_[$firstcyl] ne @_[$lastcyl]) {
                    print OUTPUT "@_[$lastcyl]\n";
                }
                $typechanges .= "t\n$partnumber\n@_[$parttype]\n";
            }
        }

        # handle bootable partitions
        if (@_[$bootable] =~ /\*/) {
            print OUTPUT "a\n$partnumber\n";
        }
    } else {
        # If we got here, the current line does not have a partition in it.

        # Get the geometry for fdisk. Force fdisk to use the current
        # geometry at restoration time. Comment this out for
        # tomstrbt's fdisk; it doesn't like it.

        if ($_ =~ /heads.*sectors.*cylinders/i) {
#           print $_;               # again, for grins.
            chop;
            @geometry = split (/ /, $_);
            $geometry = "-H $geometry[0] -S $geometry[2] -C $geometry[4]";
#           print $geometry;
        }
    }
}

# Append all the partition type changes, validate, and print out the
# results.

print OUTPUT "${typechanges}v\nw\n";

close (OUTPUT);
close (FDISK);


open (OUTPUT, "> ${outputfilepath}bin/make.$outputfilename")
    or die "Couldn't open output file ${outputfilepath}bin/make.$outputfilename.\n";

print OUTPUT <<FINIS;
#! /bin/sh

# A script to restore the partition data of a hard drive and format
# the partitions. Created at bare metal backup time by the Perl script
# make.fdisk.
FINIS

&gpl (*OUTPUT, "2001");

print OUTPUT <<FINIS;

swapoff -a
# Hideously disty dependent! Turn off LVM.
if [ -e /etc/init.d/lvm ] ; then
    /etc/init.d/lvm stop
fi
if [ -e /etc/init.d/lvm2 ] ; then
    /etc/init.d/lvm2 stop
fi

export blockcheck=\$1;

if [ "\$blockcheck" != "-c" ] && [ -n "\$blockcheck" ]
then
    echo "\${0}: automated restore with no human interaction."
    echo "\${0}: -c: block check during file system making."
    exit 1;
fi

FINIS

# Clean the old partition table out. Turn off swap in case we're using
# it.

# print OUTPUT "dd if=/dev/zero of=$device bs=512 count=2\n\nsync\n\n";
print OUTPUT "dd if=/dev/zero of=$device bs=1024 count=2000\n\nsync\n\n";


# command for fdisk

$fdiskcmd .= "# see if we have sfdisk & if so use it.\n";
$fdiskcmd .= "if which sfdisk ; then\n";
$fdiskcmd .= "  echo \"Using sfdisk.\"\n";
$fdiskcmd .= "  sfdisk $geometry $device < ../metadata/${outputfilename}.sfd\n";
$fdiskcmd .= "else\n";
$fdiskcmd .= "  echo \"using fdisk.\"\n";
$fdiskcmd .= "  fdisk $geometry $device \< ../metadata/$outputfilename\n";
$fdiskcmd .= "fi\n\nsync\n\n";


print OUTPUT $fdiskcmd;
print OUTPUT $format;

print OUTPUT "fdisk -l \"$device\"\n";

close (OUTPUT);

# Now build the script that will build the mount points on the root
# and other partitions.

open (OUTPUT, "> ${outputfilepath}bin/mount.$outputfilename")
    or die "Couldn't open output file ${outputfilepath}bin/make.$outputfilename.\n";

print OUTPUT <<FINIS;
#! /bin/sh

# A script to create a minimal directory tree on the target hard drive
# and mount the partitions on it. Created at bare metal backup time by
# the Perl script make.fdisk.
FINIS

&gpl (*OUTPUT, "2001");

print OUTPUT <<FINIS;

# WARNING: If your Linux system mount partitions across hard drive
# boundaries, you will have multiple "mount.dev.* scripts. You must
# ensure that they run in the proper order. The root partition should
# be mounted first, then the rest in the order they cascade. If they
# cross mount, you'll have to handle that manually.

FINIS


# We have a hash of mount points and devices in %mountpoints. However,
# we have to process them such that directories are built on the
# appropriate target partition. E.g. where /usr/local is on its own
# partition, we have to mount /usr before we build /usr/local. We can
# ensure this by sorting them. Shorter mount point paths will be built
# first. We can't sort a hash directly, so we use an array.

# We build commands to create the appropriate mount points and then
# mount the partitions to the mount points. This is in preparation for
# untarring the contents of the ZIP disk, done in restore.metadata.

# In case it's all one big partition...
print OUTPUT "mkdir -p $target\n";

foreach $point ( sort keys %mountpoints) {
    print OUTPUT "\n# $point is the mountpoint for";
    print OUTPUT " device $mountpoints{$point}.\n";
    print OUTPUT "mkdir -p $target$point\n";
    print OUTPUT "mount $mountpoints{$point} $target$point\n";
}

print OUTPUT "\nmount | grep -i \"/target\"\n";

close (OUTPUT);

# These scripts are dangerous & should only be visible to root.

chmod 0700, "${outputfilepath}bin/make.$outputfilename";
chmod 0700, "${outputfilepath}bin/mount.$outputfilename";
chmod 0600, "${outputfilepath}metadata/${outputfilename}*";

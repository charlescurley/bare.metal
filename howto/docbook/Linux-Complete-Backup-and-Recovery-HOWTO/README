# Abstract

Imagine your disk drive has just become a very expensive hockey
puck. Imagine you have had a fire, and your computer case now looks
like something Salvador Dalı̃ would like to paint. Now what? Total
restore, sometimes called bare metal recovery, is the process of
rebuilding a computer after a catastrophic failure. In order to make
a total restoration, you must have complete backups, not only of your
file system, but of partition information and other data. This HOWTO
is a step-by-step tutorial on how to back up a Linux computer so as to
be able to make a bare metal recovery, and how to make that bare metal
recovery. It includes some related scripts.

# Copyright and Permissions

Copyright © 2001 through last date of modification Charles Curley and
distributed under the terms of the GNU Free Documentation License
(GFDL) license. Permission is granted to copy, distribute and/or
modify this document under the terms of the GNU Free Documentation
License, Version 1.1 or any later version published by the Free
Software Foundation; with no Invariant Sections, with no Front-Cover
Texts, and with no Back-Cover Texts. A copy of the license is included
in the section entitled “GNU Free Documentation License”.

This was originally prepared for the Linux Documentation Project,
http://www.tldp.org/. It is now available on Github, at
https://github.com/charlescurley.

The HOWTO is available in a number of formats. See the Makefile for
possible targets.

The largest defect of this HOWTO is that there is no discussion of
EFI. Contributions are welcome.

If you just want the scripts, see the subdirectory `src`. Rename the
files there by removing the `.s` at the end of the file name. or build
the directory `scripts`.

# Building the Howto

Debian packages you may want, among others:

```
apt install make jade jadetex docbook ldp-docbook-dsssl lynx
```

This directory has the SGML source and related files for the Linux
Complete Backup and Recovery HOWTO. It should have everything you need
by way of source to build the HOWTO in various formats such as pdf,
HTML and TeX.

Run `make clean`, then `make scripts`. That will build some
directories and do some other stuff for you. Then you can run `make
all` to build the whole kazoo, or `make html` to build just the html
files, etc. For a complete list of the available targets, see the file
Makefile.

Making the .dvi and .pdf files may fail. Simply run the same make
command again.

The sources for the scripts are in the subdirectory `src`. Copies
exactly as I use them on my test environment are in the subdirectory
`scripts`. To install the scripts, cd to `scripts` and run `install`
as root.

With the small amount of editing described in the HOWTO the scripts
should be ready for you to use. They are here so that the SGML source
for the HOWTO can incorporate them by inclusion, rather like C's
`#include`. Before the SGML translator code can use the scripts, some
SGML cruft has to be added to each one. The cooked scripts end up in
the directory `cooked`.

You may add scripts to the `src` subdirectory. Add them to the
file src/Makefile. Make sure you call the new script from `cooked` or
it won't pass SGML verification. See the <!ENTITY ... > tags at the
top of the SGML source file for examples.

The target `clean` gets rid of intermediate files like the cooked
scripts and all of the final production. Use it to be sure you have
killed off any intermediate cruft. Then run `make scripts`.

You may have to edit the paths to the style sheets. This works on
Debian 10.5 "buster". BTW, I use GNU Make version 4.2.

Enjoy. Happy backing up.

# A makefile for adding SGML cruft to our scripts so they can be
# included in the main document.

# Clean out the suffixes
.SUFFIXES:

# Now add the one that matters.
.SUFFIXES: .cooked .s

# Our recipe
.s.cooked:; echo "rebuilding $@"
	cp -rp $< ../scripts/$*
	chmod u+x ../scripts/$*
	umask 066 && echo -n '<![ CDATA [' > $@
	cat $< >> $@
	echo ']]>' >> $@
	cp -rp $@ ../cooked/$*

all: back.up.all.cooked back.up.all.ssh.cooked dev.hda.cooked dev.hda.sfd.cooked first.stage.cooked get.target.cooked get.tester.old.cooked get.tester.cooked install.cooked make.dev.hda.cooked make.fdisk.cooked make.lvs.cooked mount.dev.hda.cooked mount.lvs.cooked restore.all.cooked restore.all.ssh.cooked restore.metadata.cooked restore.tester.old.cooked restore.tester.cooked save.metadata.cooked

back.up.all.cooked: back.up.all.s

back.up.all.ssh.cooked: back.up.all.ssh.s

dev.hda.cooked: dev.hda.s

dev.hda.sfd.cooked: dev.hda.sfd.s

first.stage.cooked: first.stage.s

get.target.cooked: get.target.s

get.tester.old.cooked: get.tester.old.s

get.tester.cooked: get.tester.s

install.cooked: install.s

make.dev.hda.cooked: make.dev.hda.s

make.fdisk.cooked: make.fdisk.s

make.lvs.cooked: make.lvs.s

mount.dev.hda.cooked: mount.dev.hda.s

mount.lvs.cooked: mount.lvs.s

restore.all.cooked: restore.all.s

restore.all.ssh.cooked: restore.all.ssh.s

restore.metadata.cooked: restore.metadata.s

restore.tester.old.cooked: restore.tester.old.s

restore.tester.cooked: restore.tester.s

save.metadata.cooked: save.metadata.s

clean:
	rm *.cooked

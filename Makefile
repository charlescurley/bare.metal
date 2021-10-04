# a makefile for generating the Bare Metal Recovery HOW-TO

# Clean out the suffixes
.SUFFIXES:

# VERSION := $(shell egrep --only-matching --max-count=1 'LCBRH-[0-9]+-[0-9]+' tag | egrep --only-matching '[0-9]+-[0-9]+' | sed s/-/./ | sed s/.0/./)
# VERSION = '2.5'
VERSION := $(shell grep --max-count 1 --only-matching \<revnumber\>.*\<\/revnumber\> Linux-Complete-Backup-and-Recovery-HOWTO.sgml | grep --only-matching [0-9.]* )

# Options for jade. If I read the rather terse command line help
# correctly, this is to allow it up to 65535 errors. You should not
# need this many.
JADEOPTS = -E 65535

# The base name of the document
DOCUMENT = Linux-Complete-Backup-and-Recovery-HOWTO

# The web server directory. This will be mirrored to the web server
# SERVER = /home/ccurley/public_html/crcweb/$(DOCUMENT)
SERVER = /home/charles/public_html/charlescurley.com/$(DOCUMENT)

# Some style sheet selections. Note the escapes for the \ and the #.
# ldpdslpath = /usr/share/sgml/docbook/dsssl-stylesheets
# ldpdslpath := $(shell pwd)
ldpdslpath = /usr/share/sgml/docbook/stylesheet/dsssl/ldp/
indexdsl = -d $(ldpdslpath)/ldp.dsl
dslhtml = -d $(ldpdslpath)/ldp.dsl\\\#html
dslprint = -d $(ldpdslpath)/ldp.dsl\\\#print

# All the scripts we depend on....
SCRIPTS := $(shell ls src/*.s)

cooked:
	-mkdir cooked scripts $(DOCUMENT) $(DOCUMENT).junk $(DOCUMENT).smooth

clean:
	echo Document is $(DOCUMENT)
	for S in cooked scripts $(DOCUMENT) $(DOCUMENT)-$(VERSION)* $(DOCUMENT).aux $(DOCUMENT).dvi $(DOCUMENT).junk $(DOCUMENT).log $(DOCUMENT).out $(DOCUMENT).pdf $(DOCUMENT).ps $(DOCUMENT).rtf $(DOCUMENT).smooth $(DOCUMENT).tex $(DOCUMENT).txt ; do \
	if [ -e $$S ] ; then \
	    rm -r $$S ; \
	fi \
	done
	cd src && make clean
	mkdir cooked scripts $(DOCUMENT) $(DOCUMENT).junk $(DOCUMENT).smooth

# .PHONY: scripts
scripts: cooked
	cd src && make all

$(DOCUMENT)/index.html: $(DOCUMENT).sgml scripts $(SCRIPTS)
	rm -r $(DOCUMENT).junk
	mv $(DOCUMENT) $(DOCUMENT).junk
	mkdir $(DOCUMENT)
	cd $(DOCUMENT) ; /usr/bin/jade $(JADEOPTS) -t sgml -i html $(indexdsl) $(dslhtml) ../$(DOCUMENT).sgml

# this target makes it easier to type as a target name. OK, I'm lazy.
chunky: $(DOCUMENT)/index.html


$(DOCUMENT).smooth/$(DOCUMENT).smooth.html: $(DOCUMENT).sgml scripts $(SCRIPTS)
	/usr/bin/jade $(JADEOPTS) -V nochunks -t sgml -i html $(indexdsl) $(dslhtml) $(DOCUMENT).sgml > $(DOCUMENT).smooth/$(DOCUMENT).smooth.html
smooth: $(DOCUMENT).smooth/$(DOCUMENT).smooth.html

html: chunky smooth

$(DOCUMENT).txt: $(DOCUMENT).smooth/$(DOCUMENT).smooth.html
	lynx $(DOCUMENT).smooth/$(DOCUMENT).smooth.html --dump --nolist > $(DOCUMENT).txt

text: $(DOCUMENT).txt

$(DOCUMENT).rtf: $(DOCUMENT).sgml scripts $(SCRIPTS)
	jade $(JADEOPTS) -t rtf -V rtf-backend $(dslprint) $(DOCUMENT).sgml
rtf: $(DOCUMENT).rtf

$(DOCUMENT).tex: $(DOCUMENT).sgml scripts $(SCRIPTS)
	jade $(JADEOPTS) -t tex -V tex-backend $(dslprint) $(DOCUMENT).sgml
tex: $(DOCUMENT).tex

# It seems to be necessary to run this thrice in order to get the TOC
# to work correctly. I don't understand it either.

$(DOCUMENT).dvi: $(DOCUMENT).tex scripts $(SCRIPTS)
	jadetex $(DOCUMENT).tex
	jadetex $(DOCUMENT).tex
	jadetex $(DOCUMENT).tex

dvi: $(DOCUMENT).dvi


$(DOCUMENT).ps: $(DOCUMENT).dvi scripts $(SCRIPTS)
	dvips -f $(DOCUMENT).dvi -o $(DOCUMENT).ps #  -The 1.5cm,3cm ?? We don't need this, but non-US might.

ps: $(DOCUMENT).ps


# It seems to be necessary to run this thrice in order to get the TOC
# to work correctly, and to get the TOC into to the bookmarks panel on
# the left side of the acroread reader. I don't understand it either.

$(DOCUMENT).pdf: $(DOCUMENT).tex scripts $(SCRIPTS)
	pdfjadetex $(DOCUMENT).tex
	pdfjadetex $(DOCUMENT).tex
	pdfjadetex $(DOCUMENT).tex

pdf: $(DOCUMENT).pdf


all: html rtf tex dvi ps pdf text

# The source tarball for download
$(DOCUMENT)-$(VERSION).tar.bz2: bare.metal.backup.excludes README.md src $(DOCUMENT).sgml Makefile images COPYING ldp.dsl all
	mkdir -p $(DOCUMENT)-$(VERSION)
	cp -rp bare.metal.backup.excludes README.md src scripts $(DOCUMENT).sgml Makefile images $(DOCUMENT)-$(VERSION)
	-cp -rpL COPYING ldp.dsl $(DOCUMENT)-$(VERSION)
	rm -rf $(DOCUMENT)-$(VERSION)/scripts/*~
	rm -rf $(DOCUMENT)-$(VERSION)/src/*~
	rm -rf $(DOCUMENT)-$(VERSION)/src/*.cooked
	tar -cvjf $(DOCUMENT)-$(VERSION).tar.bz2 $(DOCUMENT)-$(VERSION)
	rm -r $(DOCUMENT)-$(VERSION)

dist: $(DOCUMENT)-$(VERSION).tar.bz2

# Be sure to sign the RPMs after you make them!!

# find $(rpm --eval "%{_topdir}") -iname 'Linu*rpm' -exec rpm --addsign {} +

# rpms: dist
# 	cp -rp $(DOCUMENT)-$(VERSION).tar.bz2 `rpm --eval "%{_sourcedir}"`
# 	rpmbuild -ba Linux-Complete-Backup-and-Recovery-HOWTO.spec

ship: all dist
	# The chunky version for on-line viewing
	-rm -r $(SERVER)
	mkdir $(SERVER)
	cp -rp $(DOCUMENT) $(SERVER)
	cp -rp images $(SERVER)

	# PDF PS, and text versions for download
	cp -p $(DOCUMENT).pdf $(SERVER)/$(DOCUMENT)-$(VERSION).pdf
	cp -p $(DOCUMENT).ps $(SERVER)/$(DOCUMENT)-$(VERSION).ps
	cp -p $(DOCUMENT).txt $(SERVER)/$(DOCUMENT)-$(VERSION).txt
	bzip2 -9 $(SERVER)/$(DOCUMENT)-$(VERSION).ps
	bzip2 -9 $(SERVER)/$(DOCUMENT)-$(VERSION).pdf
	bzip2 -9 $(SERVER)/$(DOCUMENT)-$(VERSION).txt

	# Smooth version for download
	tar -cvf $(DOCUMENT)-$(VERSION).smooth.html.tar $(DOCUMENT).smooth/$(DOCUMENT).smooth.html images
	bzip2 -9 $(DOCUMENT)-$(VERSION).smooth.html.tar
	mv  $(DOCUMENT)-$(VERSION).smooth.html.tar.bz2 $(SERVER)/

	# Chunky version for download
	tar -cvf $(DOCUMENT)-$(VERSION).chunky.html.tar $(DOCUMENT) images
	bzip2 -9 $(DOCUMENT)-$(VERSION).chunky.html.tar
	mv $(DOCUMENT)-$(VERSION).chunky.html.tar.bz2  $(SERVER)/


	# The source for download. Requires dist:. But run it first, sign the RPMs, then run ship:.
	cp -rp $(DOCUMENT)-$(VERSION).tar.bz2 $(SERVER)/

# 	mkdir -p $(SERVER)/srpms $(SERVER)/rpms

# 	cp -rp `rpm --eval "%{_srcrpmdir}"`/$(DOCUMENT)-$(VERSION)*rpm $(SERVER)/srpms
# 	cp -rp `rpm --eval "%{_rpmdir}"`/noarch/$(DOCUMENT)*rpm $(SERVER)/rpms

# 	createrepo -q $(SERVER)/srpms
# 	createrepo -q $(SERVER)/rpms

	cd $(SERVER) ; ln -s $(DOCUMENT)-$(VERSION).tar.bz2 $(DOCUMENT)-latest.tar.bz2
	cd $(SERVER) ; ln -s $(DOCUMENT)-$(VERSION).txt.bz2 $(DOCUMENT)-latest.txt.bz2
	cd $(SERVER) ; ln -s $(DOCUMENT)-$(VERSION).smooth.html.tar.bz2 $(DOCUMENT)-latest.smooth.html.tar.bz2
	cd $(SERVER) ; ln -s $(DOCUMENT)-$(VERSION).ps.bz2 $(DOCUMENT)-latest.ps.bz2
	cd $(SERVER) ; ln -s $(DOCUMENT)-$(VERSION).pdf.bz2 $(DOCUMENT)-latest.pdf.bz2
	cd $(SERVER) ; ln -s $(DOCUMENT)-$(VERSION).chunky.html.tar.bz2 $(DOCUMENT)-latest.chunky.html.tar.bz2
	cd $(SERVER) ; sha256sum *.bz2 > sha256sums ; sha512sum *.bz2 > sha512sums
	ls -l $(SERVER)

install:
	# use the script, Luke.
	cd scripts && ./install

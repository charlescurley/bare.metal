# -*- rpm-spec -*-

# Time-stamp: <2007-08-16 16:00:50 ccurley Linux-Complete-Backup-and-Recovery-HOWTO.spec>

# This spec file is believed to work on Fedora 7. It has not been
# tested on any other flavor of Linux.

Name:           Linux-Complete-Backup-and-Recovery-HOWTO
Version:        2.3
Release: 4%{?dist}
Summary:        Scripts to back up for bare metal restoration

Group:          Applications/Archiving
License:        GPLv2+
URL:            http://www.charlescurley.com/Linux-Complete-Backup-and-Recovery-HOWTO.html
BuildRoot:      %{_tmppath}/%{name}-%{version}-%{release}-root-%(%{__id_u} -n)
buildarch:      noarch

# The source should also be available from the Linux Documentation
# Project's CVS, at http://cvs.tldp.org/. The tag is of the form
# "LCBRH-X-0Y" where X is the major and Y the minor version
# number. Single digit minor numbers should have a leading zero. Run,
# e.g., "cvs status -v Linux-Complete-Backup-and-Recovery-HOWTO.sgml"
# to get the most recent tag. I build RPMs locally, and they may be
# more recent than the LDP copies. Also see the file "tag".

Source:         http://www.charlescurley.com/Linux-Complete-Backup-and-Recovery-HOWTO/%{name}-%{version}.tar.bz2
Vendor:         Charles Curley

%package doc
Summary:        Documentation for bare metal restoration
Group:          Applications/Archiving
License:        GFDL

BuildRequires:  docbook-dtds
BuildRequires:  jadetex
BuildRequires:  lynx

# Commented out because rpmbuild incorrectly reports
# docbook-style-dsssl as AWOL.

# BuildRequires:  docbook-style-dsssl

%description

A set of scripts to back up and restore a mimimal system for bare
metal restoration. They are useful on i386 systems. Patches for others
are welcome.

Install this package on clients, and the documentation package where
you want it.

%description doc

The documentation, in several formats, for the
Linux-Complete-Backup-and-Recovery-HOWTO.

%prep
%setup -q


%build


%install
rm -rf %{buildroot}
make all DESTDIR=%{buildroot}
make install DESTDIR=%{buildroot}

%clean
rm -rf %{buildroot}


%files
%defattr(-,root,root,-)

%attr(0744 root root) /etc/bare.metal.recovery

# Having specified the directory, are the next two lines necessary?
# Apparently not, as they generate warnings....

# %attr(0744 root root) /etc/bare.metal.recovery/first.stage
# %attr(0744 root root) /etc/bare.metal.recovery/restore.metadata
%attr(0744 root root) /usr/sbin/make.fdisk
%attr(0744 root root) /usr/sbin/save.metadata
%attr(0700 root root) /var/lib/bare.metal.recovery

%doc COPYING

%files doc
%defattr(-,root,root,-)

%doc Linux-Complete-Backup-and-Recovery-HOWTO
%doc Linux-Complete-Backup-and-Recovery-HOWTO.pdf
%doc Linux-Complete-Backup-and-Recovery-HOWTO.ps
%doc Linux-Complete-Backup-and-Recovery-HOWTO.rtf
%doc Linux-Complete-Backup-and-Recovery-HOWTO.smooth
%doc Linux-Complete-Backup-and-Recovery-HOWTO.txt
%doc images

%changelog
* Thu Aug 16 2007 Charles Curley <ccurley@charlesc.localdomain> - 2.3-4
- Adjusted package license per recent emails on Fedora Maintainers list, various Fedora wiki pages.

* Tue Aug 14 2007 Charles Curley <ccurley@charlesc.localdomain> - 2.3-3
- Changes per comment 3 in bugzilla entry 250747, mostly changing $RPM_BUILD_ROOT to %{buildroot}.

* Thu Aug  9 2007 Charles Curley <ccurley@charlesc.localdomain> - 2.3-2
- Added a copy of the License (COPYING) and added it as a %doc.

* Fri Jul 27 2007 Charles Curley <ccurley@charlesc.localdomain> - 2.3-1
- Initial version


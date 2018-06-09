# -*- shell-script -*-

# Copyright 2018 through the last date of modification, Charles Curley.

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

# Do post-processing, such as caclulating check sums, for a recently
# completed archive. Call from the archive directory's get script,
# after it has run get.archive and especially get.target.

echo
echo Doing sha512 checksums...
find $host.$DATE $host.$DATE.*.bz2 -type f | sort | xargs sha512sum >  $host.$DATE.all.sha512sums
find $host.$DATE $host.$DATE.*.bz2 -type f | sort | xargs sha256sum >  $host.$DATE.all.sha256sums

# Test copied files
sha512sum --quiet -c $host.$DATE.sha512sums
sha256sum --quiet -c $host.$DATE.sha256sums

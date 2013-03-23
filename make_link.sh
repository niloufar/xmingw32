#!/bin/bash
# vim: tabstop=4 fileformat=unix fileencoding=utf-8 filetype=sh

# license: Apatche v2.0

PREFIX=`dirname "$0"`
if [ "" = "${XMINGW}" ]
then
  . "${PREFIX}/scripts/env.sh"
fi

function make_symlink() {
local sym=$1
local rl=$2
	if test -e ${sym}
	then
		echo "exist: ${sym}"
	else
		echo "linking: ${sym} from ${rl}"
		ln -s -T "${rl}" "${sym}"
	fi
}

# mingw gcc and binutils
chost=i686-w64-mingw32
chost64=x86_64-w64-mingw32
source=/usr/bin
destination=${XMINGW}/bin
destination64=${XMINGW}/bin64
mkdir -p ${destination}
mkdir -p ${destination64}
while read fl
do
	sym="${destination}/${fl}"
	rl="${source}/${chost}-${fl}"
	make_symlink "${sym}" "${rl}"
	sym="${destination}/${TARGET}-${fl}"
	make_symlink "${sym}" "${rl}"

	sym="${destination64}/${fl}"
	rl="${source}/${chost64}-${fl}"
	make_symlink "${sym}" "${rl}"
	sym="${destination64}/${TARGET}-${fl}"
	make_symlink "${sym}" "${rl}"
done <<- EOS
ar
as
c++
cpp
dlltool
dllwrap
g++
gcc
gcov
gprof
ld
nm
objcopy
objdump
ranlib
readelf
strip
windmc
windres
EOS

# my scripts

source=${XMINGW}/scripts
destination=${XMINGW}/bin
while read fl
do
	sym="${destination}/${fl}"
	rl="${source}/${fl}"
	make_symlink "${sym}" "${rl}"
done <<- EOS
build-cc
EOS

source=${XMINGW}/scripts
destination=${XMINGW}
while read fl
do
	sym="${destination}/${fl}"
	rl="${source}/${fl}"
	make_symlink "${sym}" "${rl}"
done <<- EOS
cross
env.sh
replibtool.sh
reppc.sh
EOS

source=${XMINGW}/scripts
destination=${XMINGW}
while read fl
do
	sym="${destination}/cross-${fl}"
	rl="${source}/cross-${fl}"
	make_symlink "${sym}" "${rl}"
	sym="${destination}/cross-pp${fl}"
	make_symlink "${sym}" "${rl}"
done <<- EOS
cmake
configure
EOS


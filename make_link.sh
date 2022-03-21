#!/bin/bash
# vim: tabstop=4 fileformat=unix fileencoding=utf-8 filetype=sh

# license: Apache v2.0

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
	sym="${destination}/${chost}-${fl}"
	make_symlink "${sym}" "${rl}"

	sym="${destination64}/${fl}"
	rl="${source}/${chost64}-${fl}"
	make_symlink "${sym}" "${rl}"
	sym="${destination64}/${chost64}-${fl}"
	make_symlink "${sym}" "${rl}"
done <<- EOS
ar
as
cc
c++
cpp
dlltool
dllwrap
g++
gcc
gcov
gprof
ld
ld.bfd
nm
objcopy
objdump
ranlib
readelf
strip
windmc
windres
EOS

# mingw-w64 の pkg-config が使いづらいため、素直にネイティブの pkg-config を使用する。
	fl="pkg-config"
	sym="${destination}/${chost}-${fl}"
	rl="`which ${fl}`"
	make_symlink "${sym}" "${rl}"

	sym="${destination64}/${chost64}-${fl}"
	make_symlink "${sym}" "${rl}"


# my scripts

# ホストのコンパイラを使うためのスクリプト。
source=${XMINGW}/scripts
destination=${XMINGW}/bin
destination64=${XMINGW}/bin64
while read fl
do
	sym="${destination}/${fl}"
	rl="${source}/${fl}"
	make_symlink "${sym}" "${rl}"

	sym="${destination64}/${fl}"
	rl="${source}/${fl}"
	make_symlink "${sym}" "${rl}"
done <<- EOS
build-cc
EOS

# ホストのコンパイラを使うためのスクリプト。
source=${XMINGW}/scripts
destination=${XMINGW}/bin
destination64=${XMINGW}/bin64
IFS="	"	# タブ。
while read cmd fl
do
	rl="${source}/${fl}"

	sym="${destination}/${cmd}"
	make_symlink "${sym}" "${rl}"

	sym="${destination64}/${cmd}"
	make_symlink "${sym}" "${rl}"
done <<- EOS
rustc	cross-rust
cargo	cross-rust
wine	cross-wine
g-ir-scanner	cross-gir
gtkdoc-scangobj	cross-gir
ldd	mingw-w64-ldd
EOS

# ${XMINGW}/* で使えるスクリプトのリンク。
source=${XMINGW}/scripts
destination=${XMINGW}
while read fl
do
	sym="${destination}/${fl}"
	rl="${source}/${fl}"
	make_symlink "${sym}" "${rl}"
done <<- EOS
env.sh
cross
cross-host
cross-meson
cross-wine
package
replibtool.sh
reppc.sh
EOS

# ${XMINGW}/* で使えるスクリプトのリンクで、内部で ../ するリンクも作成する。
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

# ディレクトリーの作成。
mkdir -p "${XLOCAL}"
mkdir -p "${XLOCAL}/libs"
mkdir -p "${XLOCAL}/libs64"
mkdir -p "${XLOCAL}/archives"
mkdir -p "${XLOCAL}/src"
mkdir -p "${XLOCAL}/src/build"
mkdir -p "${XLOCAL}/src/packaging"



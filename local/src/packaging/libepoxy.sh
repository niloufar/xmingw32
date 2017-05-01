#!/bin/bash
# vim: tabstop=4 fileformat=unix fileencoding=utf-8 filetype=sh

# license: Apache v2.0

if [ "" = "${IN_PACKAGE_SCRIPT}" ]
then
	echo "FAIL: \${XMINGW}/package から実行してください。"
	exit 1
fi


# ARCH は package が設定している。
# XLIBRARY_SOURCES は xmingw のための環境変数。 env.sh で設定している。
init_var() {
	#XLIBRARY_SET=${XLIBRARY}/gimp_build_set

	# package に返す変数。
	MOD=libepoxy
	[ "" = "${VER}" ] && VER="git-20062c2"
	[ "" = "${REV}" ] && REV=1
	DIRECTORY="${MOD}-${VER}"

	# 内部で使用する変数。
	__ARCHIVEDIR="${XLIBRARY_SOURCES}/libs/pic"
	__ARCHIVE="${MOD}-${VER}"
#	__PATCH_ARCHIVE="${MOD}_${VER}-${PATCH}"

	__BINZIP=${MOD}-${VER}-${REV}-bin_${ARCHSUFFIX}
	__DEVZIP=${MOD}-dev-${VER}-${REV}_${ARCHSUFFIX}
}

dependencies() {
	cat <<EOS
jpeg
libpng
tiff
zlib
EOS
}

optional_dependencies() {
	cat <<EOS
EOS
}

license() {
	cat <<EOS
MIT license

EOS
}


run_expand_archive() {
local name
	name=`find_archive "${__ARCHIVEDIR}" ${__ARCHIVE}` &&
	expand_archive "${__ARCHIVEDIR}/${name}"
}

pre_configure() {
	if [ ! -e configure ]
	then
		NOCONFIGURE=1 $XMINGW/cross-host sh ./autogen.sh
	fi
}

run_configure() {
	CC="gcc `${XMINGW}/cross --archcflags`" \
	CXX="g++ `${XMINGW}/cross --archcflags`" \
	CPPFLAGS="`${XMINGW}/cross --cflags`" \
	LDFLAGS="`${XMINGW}/cross --ldflags` \
	-Wl,--enable-auto-image-base -Wl,-s" \
	CFLAGS="-pipe -O2 -fomit-frame-pointer -ffast-math " \
	CXXFLAGS="-pipe -O2 -fomit-frame-pointer -ffast-math " \
	${XMINGW}/cross-configure --enable-shared --disable-static --prefix="${INSTALL_TARGET}"
}

run_make() {
	${XMINGW}/cross make all install
}

pre_pack() {
local docdir="${INSTALL_TARGET}/share/doc/${MOD}"
	mkdir -p "${docdir}" &&
	# ライセンスなどの情報は share/doc/<MOD>/ に入れる。
	cp COPYING "${docdir}/."
}

run_pack() {
	cd "${INSTALL_TARGET}" &&
	pack_archive "${__BINZIP}" bin/*.dll share/doc &&
	pack_archive "${__DEVZIP}" include lib/*.a lib/pkgconfig  &&
	store_packed_archive "${__BINZIP}" &&
	store_packed_archive "${__DEVZIP}"
}




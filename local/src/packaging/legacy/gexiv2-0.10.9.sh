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
	XLIBRARY_SET=${XLIBRARY}/gimp_build_set

	# package に返す変数。
	MOD=gexiv2
	[ "" = "${VER}" ] && VER=0.10.9
	[ "" = "${REV}" ] && REV=1
	DIRECTORY="${MOD}-${VER}"

	# 内部で使用する変数。
	__ARCHIVEDIR="${XLIBRARY_SOURCES}/libs/pic"
	__ARCHIVE="${MOD}-${VER}"
#	__PATCH_ARCHIVE="${MOD}_${VER}-${PATCH}"

	__BINZIP=${MOD}-${VER}-${REV}-bin_${ARCHSUFFIX}
	__DEVZIP=${MOD}-dev-${VER}-${REV}_${ARCHSUFFIX}
	__DOCZIP=${MOD}-${VER}-${REV}-doc_${ARCHSUFFIX}
}

dependencies() {
	cat <<EOS
exiv2
glib
EOS
}

optional_dependencies() {
	cat <<EOS
gobject-introspection
python2
python3
EOS
}

license() {
	cat <<EOS
GNU GENERAL PUBLIC LICENSE
Version 2, June 1991
EOS
}


run_expand_archive() {
local name
	name=`find_archive "${__ARCHIVEDIR}" ${__ARCHIVE}` &&
	expand_archive "${__ARCHIVEDIR}/${name}"
}

:run_patch() {
local name
	# name=`find_archive "${__ARCHIVEDIR}" ${__PATCH_ARCHIVE}` &&
	# 	patch_debian "${__ARCHIVEDIR}/${name}"
	sed -i -e 's/^\(REQUIRED_CXXFLAGS = \)-Wl,-lstdc++/\1/' Makefile.in

	# [0.10.5] exiv2-0.26 でビルドできなくなった。
	sed -i.orig -e 's/virtual long size /virtual size_t size /' gexiv2/gexiv2-stream-io.h
	sed -i.orig -e 's/^long StreamIo::size /size_t StreamIo::size /' gexiv2/gexiv2-stream-io.cpp
}

run_configure() {
	CC="gcc `${XMINGW}/cross --archcflags`" \
	CPPFLAGS="`${XMINGW}/cross --archcflags --cflags` \
		-pipe -O2 -fomit-frame-pointer -ffast-math" \
	LDFLAGS="`${XMINGW}/cross --ldflags` \
		-Wl,--enable-auto-image-base -Wl,-s" \
	${XMINGW}/cross-meson _build --prefix="${INSTALL_TARGET}" --buildtype=release --default-library=shared  -Denable-gtk-doc=false -Ddisable-introspection=true -Ddisable-vala=true
}

run_make() {
	${XMINGW}/cross ninja -C _build &&
	${XMINGW}/cross ninja -C _build -v install
}

pre_pack() {
	# ライセンスなどの情報は share/doc/<MOD>/ に入れる。
	install_license_files "${MOD}" COPYING*
}

run_pack() {
	cd "${INSTALL_TARGET}" &&
	pack_archive "${__BINZIP}" bin/*.dll share/doc &&
	pack_archive "${__DEVZIP}" include lib/*.a lib/pkgconfig &&
	pack_archive "${__DOCZIP}" share/gtk-doc &&
	store_packed_archive "${__BINZIP}" &&
	store_packed_archive "${__DEVZIP}" &&
	store_packed_archive "${__DOCZIP}"
}




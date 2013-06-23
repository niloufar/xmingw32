#!/bin/bash
# vim: tabstop=4 fileformat=unix fileencoding=utf-8 filetype=sh

# license: Apatche v2.0

if [ "" = "${IN_PACKAGE_SCRIPT}" ]
then
	echo FAIL: \${XMINGW}/package から実行してください。
	exit 1
fi


# ARCH は package が設定している。
# XLIBRARY_SOURCES は xmingw のための環境変数鵜。 env.sh で設定している。
init_var() {
	# package に返す変数。
	MOD=pango
	if [ "" = "${VER}" ]
	then
	VER=1.33.8
	REV=1
	fi
	DIRECTORY="${MOD}-${VER}"

	# 内部で使用する変数。
	__ARCHIVEDIR="${XLIBRARY_SOURCES}/gtk+"
	__ARCHIVE="${MOD}-${VER}"

	__BINZIP=${MOD}-${VER}-${REV}-bin_${ARCHSUFFIX}
	__DEVZIP=${MOD}-dev-${VER}-${REV}_${ARCHSUFFIX}
	__TOOLSZIP=${MOD}-${VER}-${REV}-tools_${ARCHSUFFIX}
}

dependencies() {
	cat <<EOS
glib
fontconfig
freetype2
EOS
}

dependencies_opt() {
	cat <<EOS
cairo
harfbuzz
EOS
}


run_expand_archive() {
local name
	name=`find_archive "${__ARCHIVEDIR}" ${__ARCHIVE}` &&
	expand_archive "${__ARCHIVEDIR}/${name}"
}

pre_configure() {
	# --without-x が効いていない。
	# xft は x window 関係なので使わない。
	sed -i.orig -e's/,basic-x,/,/' \
				-e's|\(have_xft\)=true|\1=false|' configure
#	echo skip > /dev/null
}

run_configure() {
	CC="gcc `${XMINGW}/cross --archcflags`" \
	CPPFLAGS="`${XMINGW}/cross --cflags`" \
	LDFLAGS="`${XMINGW}/cross --ldflags` \
	-Wl,--enable-auto-image-base -Wl,-s" \
	CFLAGS="-pipe -O2 -fomit-frame-pointer -ffast-math" \
	${XMINGW}/cross-configure --enable-debug=yes --enable-introspection=no --disable-gtk-doc --enable-explicit-deps=no --with-included-modules=yes --prefix="${INSTALL_TARGET}"
}

post_configure() {
#	cp config.h.win32 config.h &&
	bash ${XMINGW}/replibtool.sh shared mix
#	echo skip > /dev/null
}

run_make() {
	${XMINGW}/cross make all install
}

run_pack() {
	(cd "${INSTALL_TARGET}" &&
	pack_archive "${__BINZIP}" bin/*.dll &&
	pack_archive "${__DEVZIP}" include lib/*.{def,a} lib/pkgconfig share/gtk-doc &&
	pack_archive "${__TOOLSZIP}" bin/*.exe share/man &&
	store_packed_archive "${__BINZIP}" &&
	store_packed_archive "${__DEVZIP}" &&
	store_packed_archive "${__TOOLSZIP}") &&

	EXAMPLESZIP=${MOD}-${VER}-${REV}-examples_${ARCH}
	7z a ${EXAMPLESZIP}.7z examples/*.exe examples/.libs

	TESTSZIP=${MOD}-${VER}-${REV}-tests_${ARCH}
	7z a ${EXAMPLESZIP}.7z tests/*.exe tests/.libs tests/*.{txt,utf8,sh}
}



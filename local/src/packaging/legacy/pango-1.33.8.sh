#!/bin/bash
# vim: tabstop=4 fileformat=unix fileencoding=utf-8 filetype=sh

# license: Apache v2.0

if [ "" = "${IN_PACKAGE_SCRIPT}" ]
then
	echo FAIL: \${XMINGW}/package から実行してください。
	exit 1
fi


# ARCH は package が設定している。
# XLIBRARY_SOURCES は xmingw のための環境変数。 env.sh で設定している。
init_var() {
	# package に返す変数。
	MOD=pango
	[ "" = "${VER}" ] && VER=1.33.8
	[ "" = "${REV}" ] && REV=1
	DIRECTORY="${MOD}-${VER}"

	# 内部で使用する変数。
	__ARCHIVEDIR="${XLIBRARY_SOURCES}/gtk+"
	__ARCHIVE="${MOD}-${VER}"

	__BINZIP=${MOD}-${VER}-${REV}-bin_${ARCHSUFFIX}
	__DEVZIP=${MOD}-dev-${VER}-${REV}_${ARCHSUFFIX}
	__DOCZIP=${MOD}-${VER}-${REV}-doc_${ARCHSUFFIX}
	__TOOLSZIP=${MOD}-${VER}-${REV}-tools_${ARCHSUFFIX}
}

dependencies() {
	cat <<EOS
glib
fontconfig
freetype2
harfbuzz
EOS
}

optional_dependencies() {
	cat <<EOS
cairo
libthai
EOS
}

license() {
	cat <<EOS
GNU LIBRARY GENERAL PUBLIC LICENSE
Version 2, June 1991
EOS
}


run_expand_archive() {
local name
	name=`find_archive "${__ARCHIVEDIR}" ${__ARCHIVE}` &&
	expand_archive "${__ARCHIVEDIR}/${name}"
}

pre_configure() {
	[ ! -e configure.orig ] && cp configure configure.orig
	# --without-x が効いていない。 xft は windows では使わない。
	sed -i -e's/,basic-x,/,/' \
				-e's|\(have_xft\)=true|\1=false|' \
				 configure
	# libthai がビルド環境に存在する場合にエラーになる。libthai に依存しない。
	sed -i -e's/,basic-x,/,/' \
				-e 's|have_libthai=true|have_libthai=false|g' \
				-e 's|=$pkg_cv_LIBTHAI_CFLAGS|=|' \
				-e 's|=$pkg_cv_LIBTHAI_LIBS|=|' \
				 configure
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
	bash ${XMINGW}/replibtool.sh shared mix static-libgcc
#	echo skip > /dev/null
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
	(cd "${INSTALL_TARGET}" &&
	pack_archive "${__BINZIP}" bin/*.dll share/doc &&
	pack_archive "${__DEVZIP}" include lib/*.{def,a} lib/pkgconfig &&
	pack_archive "${__DOCZIP}" share/gtk-doc &&
	pack_archive "${__TOOLSZIP}" bin/*.exe share/man &&
	store_packed_archive "${__BINZIP}" &&
	store_packed_archive "${__DEVZIP}" &&
	store_packed_archive "${__DOCZIP}" &&
	store_packed_archive "${__TOOLSZIP}") &&

	EXAMPLESZIP=${MOD}-${VER}-${REV}-examples_${ARCHSUFFIX}
	7z a ${EXAMPLESZIP}.7z examples/*.exe examples/.libs

	TESTSZIP=${MOD}-${VER}-${REV}-tests_${ARCHSUFFIX}
	7z a ${EXAMPLESZIP}.7z tests/*.exe tests/.libs tests/*.{txt,utf8,sh}
}



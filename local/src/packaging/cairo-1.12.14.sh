#!/bin/bash
# vim: tabstop=4 fileformat=unix fileencoding=utf-8 filetype=sh

# license: Apatche v2.0

if [ "" = "${IN_PACKAGE_SCRIPT}" ]
then
	echo FAIL: \${XMINGW}/package から実行してください。
	exit 1
fi


# ARCH は package が設定している。
# XLIBRARY_SOURCES は xmingw のための環境変数。 env.sh で設定している。
init_var() {
	# package に返す変数。
	MOD=cairo
	if [ "" = "${VER}" ]
	then
	VER=1.12.14
	REV=1
	fi
	DIRECTORY="${MOD}-${VER}"

	# 内部で使用する変数。
	__ARCHIVEDIR="${XLIBRARY_SOURCES}/gtk+"
	__ARCHIVE="${MOD}-${VER}"

	__BINZIP=${MOD}-${VER}-${REV}-bin_${ARCH}
	__DEVZIP=${MOD}-dev-${VER}-${REV}_${ARCH}
#	__TOOLSZIP=${MOD}-${VER}-${REV}-tools_${ARCH}
}

dependencies() {
	cat <<EOS
glib
fontconfig
freetyte2
libpng
pixman
zlib
EOS
}

dependencies_opt() {
	cat <<EOS
gtk+
librsvg
poppler
EOS
}

run_expand_archive() {
local name
	name=`find_archive "${__ARCHIVEDIR}" ${__ARCHIVE}` &&
	expand_archive "${__ARCHIVEDIR}/${name}"
}

run_configure() {
	png_REQUIRES=libpng16 \
	CC="gcc `${XMINGW}/cross --archcflags`" \
	CPPFLAGS="`${XMINGW}/cross --cflags`" \
	LDFLAGS="`${XMINGW}/cross --ldflags` \
	-Wl,--enable-auto-image-base -Wl,-s" \
	CFLAGS="-pipe -O2 -fomit-frame-pointer -ffast-math" \
	${XMINGW}/cross-configure --without-x --disable-xlib --disable-xcb --disable-static --enable-ft=yes --enable-win32 --prefix="${INSTALL_TARGET}"
}

post_configure() {
	bash ${XMINGW}/replibtool.sh shared mix
}

run_make() {
	${XMINGW}/cross make all install 
}

pre_pack() {
	cp -p src/cairo.def "${INSTALL_TARGET}/lib" &&

	mkdir -p "${INSTALL_TARGET}/share/doc/${THIS}" &&
	cp -p COPYING COPYING-LGPL-2.1 COPYING-MPL-1.1 "${INSTALL_TARGET}/share/doc/${THIS}"
}

run_pack() {
	(cd "${INSTALL_TARGET}" &&
	pack_archive "${__BINZIP}" bin/*.dll "share/doc/${THIS}" &&
	pack_archive "${__DEVZIP}" include lib/*.{def,a} lib/pkgconfig share/gtk-doc/ &&
	store_packed_archive "${__BINZIP}" &&
	store_packed_archive "${__DEVZIP}")

	(
	__PERFZIP=${MOD}-${VER}-${REV}-perf_${ARCH} &&
	pack_archive "${__PERFZIP}" perf/*.exe perf/cairo-perf-diff \
		perf/.libs &&
	store_packed_archive "${__PERFZIP}" &&

	__TESTSZIP=${MOD}-${VER}-${REV}-tests_${ARCH} &&
	pack_archive "${__TESTSZIP}" test/*.{exe,sh} test/.libs \
		test/*.pcf \
		test/*.{html,css,js,jpg,jp2,png} test/{pdiff,reference}
	store_packed_archive "${__TESTSZIP}"
	)
}



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
	XLIBRARY_SET="gtk gimp_build"

	# package に返す変数。
	MOD=cairo
	[ "" = "${VER}" ] && VER=1.12.14
	[ "" = "${REV}" ] && REV=1
	DIRECTORY="${MOD}-${VER}"

	# 内部で使用する変数。
	__ARCHIVEDIR="${XLIBRARY_SOURCES}/gtk+"
	__ARCHIVE="${MOD}-${VER}"

	__BINZIP=${MOD}-${VER}-${REV}-bin_${ARCHSUFFIX}
	__DEVZIP=${MOD}-dev-${VER}-${REV}_${ARCHSUFFIX}
#	__TOOLSZIP=${MOD}-${VER}-${REV}-tools_${ARCHSUFFIX}
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

optional_dependencies() {
	cat <<EOS
gdk-pixbuf
gtk+
librsvg
opengl
poppler
skia
EOS
}

run_expand_archive() {
local name
	name=`find_archive "${__ARCHIVEDIR}" ${__ARCHIVE}` &&
	expand_archive "${__ARCHIVEDIR}/${name}"
}

run_patch() {
	# 1.14.0: configure のつまらないバグ。
	(patch_adhoc -p 0 <<\EOF; return 0)
--- configure.orig
+++ configure
@@ -18930,10 +18930,10 @@
 if ac_fn_c_try_link "$LINENO"; then :
 
 
-if strings - conftest | grep noonsees >/dev/null ; then
+if strings - conftest$ac_exeext | grep noonsees >/dev/null ; then
   ax_cv_c_float_words_bigendian=yes
 fi
-if strings - conftest | grep seesnoon >/dev/null ; then
+if strings - conftest$ac_exeext | grep seesnoon >/dev/null ; then
   if test "$ax_cv_c_float_words_bigendian" = unknown; then
     ax_cv_c_float_words_bigendian=no
   else
EOF
}

pre_configure() {
	if [ ! -e "./configure" ]
	then
		NOCONFIGURE=1 $XMINGW/cross-host sh ./autogen.sh
	fi
}

run_configure() {
	# [2020/6/21] gcc -D_FORTIFY_SOURCE=2 により __memcpy_chk をリンクしようとするが
	# libssp をリンクしないためにエラーになっていた。 -lssp を追加している。
	png_REQUIRES=libpng16 \
	CC="gcc `${XMINGW}/cross --archcflags`" \
	CPPFLAGS="`${XMINGW}/cross --cflags`" \
	LDFLAGS="`${XMINGW}/cross --ldflags` -lssp \
	-Wl,--enable-auto-image-base -Wl,-s" \
	CFLAGS="-pipe -O2 -fomit-frame-pointer -ffast-math" \
	${XMINGW}/cross-configure --prefix="${INSTALL_TARGET}" --disable-static --without-x --disable-xlib --disable-qt --disable-xcb --enable-win32 --enable-png --enable-script --enable-ft=yes --enable-fc=yes --enable-ps=no --enable-pdf --enable-svg --enable-xml --enable-interpreter
}

post_configure() {
	bash ${XMINGW}/replibtool.sh shared mix static-libgcc
}

run_make() {
	${XMINGW}/cross make all install 
}

pre_pack() {
	cp -p src/cairo.def "${INSTALL_TARGET}/lib" &&

	# ライセンスなどの情報は share/licenses/<MOD>/ に入れる。
	install_license_files "${MOD}" COPYING COPYING-LGPL-2.1 COPYING-MPL-1.1
}

run_pack() {
	(cd "${INSTALL_TARGET}" &&
	pack_archive "${__BINZIP}" bin/*.dll "${LICENSE_DIR}" &&
	pack_archive "${__DEVZIP}" include lib/*.{def,a} lib/pkgconfig share/*doc &&
	store_packed_archive "${__BINZIP}" &&
	store_packed_archive "${__DEVZIP}") &&

	(
	__PERFZIP=${MOD}-${VER}-${REV}-perf_${ARCHSUFFIX} &&
	pack_archive "${__PERFZIP}" perf/*.exe perf/cairo-perf-diff \
		perf/.libs &&
	store_packed_archive "${__PERFZIP}" &&

	__TESTSZIP=${MOD}-${VER}-${REV}-tests_${ARCHSUFFIX} &&
	pack_archive "${__TESTSZIP}" test/*.{exe,sh} test/.libs \
		test/*.pcf \
		test/*.{html,css,js,jpg,jp2,png} test/{pdiff,reference}
	store_packed_archive "${__TESTSZIP}"
	)
}



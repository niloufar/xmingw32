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
	[ "" = "${VER}" ] && VER=1.17.8
	[ "" = "${REV}" ] && REV=1
	DIRECTORY="${MOD}-${VER}"

	# 内部で使用する変数。
	__ARCHIVEDIR="${XLIBRARY_SOURCES}/gtk+"
	__ARCHIVE="${MOD}-${VER}"

	__BINZIP=${MOD}-${VER}-${REV}-bin_${ARCHSUFFIX}
	__DEVZIP=${MOD}-dev-${VER}-${REV}_${ARCHSUFFIX}
	__DOCZIP=${MOD}-${VER}-${REV}-doc_${ARCHSUFFIX}
#	__TOOLSZIP=${MOD}-${VER}-${REV}-tools_${ARCHSUFFIX}
}

dependencies() {
	cat <<EOS
glib
fontconfig
freetyte2
gdk-pixbuf
libpng
librsvg
pixman
poppler
zlib
EOS
}

optional_dependencies() {
	cat <<EOS
gtk2
libspectre
lzo
opengl
skia
EOS
}

license() {
	cat <<EOS
GNU LESSER GENERAL PUBLIC LICENSE
Version 2.1, February 1999
MOZILLA PUBLIC LICENSE
Version 1.1
EOS
}

run_expand_archive() {
local name
	name=`find_archive "${__ARCHIVEDIR}" ${__ARCHIVE}` &&
	expand_archive "${__ARCHIVEDIR}/${name}"
}

run_patch() {
	# lzo2 を無効にする手段がない。
	sed -i.orig meson.build \
		-e "s|^\(lzo_dep = dependency(\)'lzo2'|\1'lzo2-disabled_'|"
}

run_configure() {
	# [2020/6/21] gcc -D_FORTIFY_SOURCE=2 により __memcpy_chk をリンクしようとするが
	# libssp をリンクしないためにエラーになっていた。 -lssp を追加している。
	CFLAGS="`${XMINGW}/cross --archcflags --cflags` \
		-pipe -O2 -fomit-frame-pointer -ffast-math" \
	CXXFLAGS="`${XMINGW}/cross --archcflags --cflags` \
		-pipe -O2 -fomit-frame-pointer -ffast-math ${OLD_CXX_ABI}" \
	LDFLAGS="`${XMINGW}/cross --ldflags` -lssp \
		-Wl,--enable-auto-image-base -Wl,-s" \
	LIBS=" -Wl,-lssp" \
	${XMINGW}/cross-meson _build --prefix="${INSTALL_TARGET}" --buildtype=release --optimization=2 --default-library=shared \
		-Dgtk_doc=true \
		-Dquartz=disabled \
		-Dxcb=disabled -Dxlib=disabled -Dxlib-xcb=disabled \
		-Dxml=enabled \
		-Dtests=disabled \
		-Dspectre=disabled
}

run_make() {
	# 複数パスはセミコロン(;)で連結する。
	# ./${MOD} でも問題ないようだ。
	WINEPATH="./src/.libs" \
	${XMINGW}/cross ninja -C _build &&
	WINEPATH="./src/.libs" \
	${XMINGW}/cross ninja -C _build install
}

pre_pack() {
	# ライセンスなどの情報は share/licenses/<MOD>/ に入れる。
	install_license_files "${MOD}" COPYING* AUTHORS*

}

run_pack() {
	(cd "${INSTALL_TARGET}" &&
	pack_archive "${__BINZIP}" bin/*.dll "${LICENSE_DIR}" &&
	pack_archive "${__DEVZIP}" include lib/*.{def,a} lib/pkgconfig &&
	pack_archive "${__DOCZIP}" share/*doc &&
	store_packed_archive "${__BINZIP}" &&
	store_packed_archive "${__DEVZIP}" &&
	store_packed_archive "${__DOCZIP}") &&

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



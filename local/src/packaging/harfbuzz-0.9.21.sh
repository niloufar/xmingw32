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
	MOD=harfbuzz
	[ "" = "${VER}" ] && VER=0.9.21
	[ "" = "${REV}" ] && REV=1
	DIRECTORY="${MOD}-${VER}"

	# 内部で使用する変数。
	__ARCHIVEDIR="${XLIBRARY_SOURCES}/libs/pic"
	__ARCHIVE="${MOD}-${VER}"

	__BINZIP=${MOD}-${VER}-${REV}-bin_${ARCHSUFFIX}
	__DEVZIP=${MOD}-dev-${VER}-${REV}_${ARCHSUFFIX}
	__TOOLSZIP=${MOD}-${VER}-${REV}-tools_${ARCHSUFFIX}
}

dependencies() {
	cat <<EOS
cairo
fontconfig
freetype2
glib
EOS
}

optional_dependencies() {
	cat <<EOS
coretext
graphite2
icu4c
EOS
}

license() {
	cat <<EOS
Old MIT license.
EOS
}


run_expand_archive() {
local name
	name=`find_archive "${__ARCHIVEDIR}" ${__ARCHIVE}` &&
	expand_archive "${__ARCHIVEDIR}/${name}"
}

run_patch() {
	# harfbuzz.pc で prefix 変数を参照するべきところを埋め込みにしている。
	(patch_adhoc -p 0 <<\EOF; return 0)
--- src/Makefile.in.orig
+++ src/Makefile.in
@@ -1782,9 +1782,9 @@
 %.pc: %.pc.in $(top_builddir)/config.status
 	$(AM_V_GEN) \
 	$(SED)	-e 's@%prefix%@$(prefix)@g' \
-		-e 's@%exec_prefix%@$(exec_prefix)@g' \
-		-e 's@%libdir%@$(libdir)@g' \
-		-e 's@%includedir%@$(includedir)@g' \
+		-e 's@%exec_prefix%@$${prefix}@g' \
+		-e 's@%libdir%@$${exec_prefix}/lib@g' \
+		-e 's@%includedir%@$${prefix}/include@g' \
 		-e 's@%VERSION%@$(VERSION)@g' \
 	"$<" \
EOF
}

# XP のための特別な処理。
run_configure_xp() {
	CC="gcc `${XMINGW}/cross --archcflags`" \
	CPPFLAGS="`${XMINGW}/cross --cflags`" \
	LDFLAGS="`${XMINGW}/cross --ldflags` \
	-Wl,--enable-auto-image-base -Wl,-s" \
	CFLAGS="-pipe -O2 -fomit-frame-pointer -ffast-math" \
	CXXFLAGS="-pipe -O2 -fomit-frame-pointer -ffast-math ${OLD_CXX_ABI}" \
	${XMINGW}/cross-configure --enable-shared --disable-static --prefix="${INSTALL_TARGET}" --with-icu=no --with-uniscribe=no
}

run_configure() {
	CC="gcc `${XMINGW}/cross --archcflags`" \
	CPPFLAGS="`${XMINGW}/cross --cflags`" \
	LDFLAGS="`${XMINGW}/cross --ldflags` \
	-Wl,--enable-auto-image-base -Wl,-s" \
	CFLAGS="-pipe -O2 -fomit-frame-pointer -ffast-math" \
	CXXFLAGS="-pipe -O2 -fomit-frame-pointer -ffast-math ${OLD_CXX_ABI}" \
	${XMINGW}/cross-configure --enable-shared --disable-static --prefix="${INSTALL_TARGET}" --with-icu=no --with-uniscribe=auto
}

post_configure() {
	# 使用する場合は bash ${XMINGW}/replibtool.sh にオプションを並べる。
	# shared ファイルを作ってくれない場合の対処。
#	bash ${XMINGW}/replibtool.sh shared
	# static なライブラリーのリンクはこうしないと libtool がいろいろ面倒をみてしまう。
#	bash ${XMINGW}/replibtool.sh mix
	# libstdc++ を静的リンクする。
	bash ${XMINGW}/replibtool.sh static-libgcc
	# 追加で libtool を書き換える場合は replibtool.sh の実行後に行う。
#	echo skip > /dev/null
}

run_make() {
	# hb-uniscribe.cc のコンパイルでエラーになるため -fpermissive している。
	${XMINGW}/cross make "UNISCRIBE_CFLAGS=-fpermissive" all install
}

pre_pack() {
local UNISCRIBE_LIBS="-lusp10 -lgdi32 -lrpcrt4"
	(cd "${INSTALL_TARGET}/lib/pkgconfig" &&
	sed -i -e"s/^Libs:.\+\$/\0 ${UNISCRIBE_LIBS}/" harfbuzz.pc &&
	echo "Requires: glib-2.0" >> harfbuzz.pc
	)
#	echo skip > /dev/null
}

run_pack() {
	cd "${INSTALL_TARGET}" &&
	pack_archive "${__BINZIP}" bin/*.dll &&
	pack_archive "${__DEVZIP}" include lib/*.{def,a} lib/pkgconfig &&
	pack_archive "${__TOOLSZIP}" bin/*.{exe,manifest,local} &&
	store_packed_archive "${__BINZIP}" &&
	store_packed_archive "${__DEVZIP}" &&
	store_packed_archive "${__TOOLSZIP}"
}



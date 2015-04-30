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
	MOD=fontconfig
	if [ "" = "${VER}" ]
	then
	VER=2.10.91
	REV=1
	fi
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
freetype2
libiconv
libxml2
EOS
}


run_expand_archive() {
local name
	name=`find_archive "${__ARCHIVEDIR}" ${__ARCHIVE}` &&
	expand_archive "${__ARCHIVEDIR}/${name}"
}

# XP のための特別な処理。
run_patch_xp() {
	# XP の %windir%\system32\msvcrt.dll に _mktemp_s が定義されていない。
	# Win7 には定義されている。
	# configure で LDFLAGS に -lmsvcr100 を渡す方がよいのかもしれない。
	patch_adhoc -p 0 <<EOF
--- src/fccompat.c.orig
+++ src/fccompat.c
@@ -96,7 +96,7 @@
     }
 #  endif
 #elif HAVE__MKTEMP_S
-   if (_mktemp_s(template, strlen(template) + 1) != 0)
+   if (_mktemp(template) != 0)
        return -1;
    fd = FcOpen(template, O_RDWR | O_EXCL | O_CREAT, 0600);
 #else
EOF
}

run_configure() {
	CC="gcc `${XMINGW}/cross --archcflags`" \
	CPPFLAGS="`${XMINGW}/cross --cflags`" \
	LDFLAGS="`${XMINGW}/cross --ldflags` \
	-Wl,-s" \
	CFLAGS="-pipe -O2 -fomit-frame-pointer -ffast-math" \
	${XMINGW}/cross-configure --enable-libxml2 --with-arch=mingw32 --prefix="${INSTALL_TARGET}"
}

post_configure() {
	# 2.11.0 の test/test-migration.c が面倒なので test を外す。
	sed -i.orig -e's/\(^\s\+conf.d \)test /\1/' Makefile
}

run_make() {
	${XMINGW}/cross make install
}

run_pack() {
	cd "${INSTALL_TARGET}" &&
	pack_archive "${__BINZIP}" bin/*.dll etc &&
	pack_archive "${__DEVZIP}" include lib/*.{a,def} lib/pkgconfig share/doc share/man/man{3,5} &&
	pack_archive "${__TOOLSZIP}" bin/*.{exe,manifest,local} share/man/man1 &&
	store_packed_archive "${__BINZIP}" &&
	store_packed_archive "${__DEVZIP}" &&
	store_packed_archive "${__TOOLSZIP}"
}



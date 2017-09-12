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
	MOD=fontconfig
	[ "" = "${VER}" ] && VER=2.10.91
	[ "" = "${REV}" ] && REV=1
	DIRECTORY="${MOD}-${VER}"

	# 内部で使用する変数。
	__ARCHIVEDIR="${XLIBRARY_SOURCES}/libs/pic"
	__ARCHIVE="${MOD}-${VER}"

	__BINZIP=${MOD}-${VER}-${REV}-bin_${ARCHSUFFIX}
	__DEVZIP=${MOD}-dev-${VER}-${REV}_${ARCHSUFFIX}
	__DOCZIP=${MOD}-${VER}-${REV}-doc_${ARCHSUFFIX}
	__TOOLSZIP=${MOD}-${VER}-${REV}-tools_${ARCHSUFFIX}
}

dependencies() {
	cat <<EOS
freetype2
libiconv
libxml2
EOS
}

optional_dependencies() {
	cat <<EOS
EOS
}

license() {
	cat <<EOS
Fontconfig License

EOS
}


run_expand_archive() {
local name
	name=`find_archive "${__ARCHIVEDIR}" ${__ARCHIVE}` &&
	expand_archive "${__ARCHIVEDIR}/${name}"
}

# XP のための特別な処理。メンテナンスしていない。
run_patch_xp() {
	run_patch &&
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

run_patch() {
	sed -i.orig -e 's/\(^\s*MemoryBarrier\) ();/\1;/' src/fcatomic.h
}

run_configure() {
	CC="gcc `${XMINGW}/cross --archcflags`" \
	CPPFLAGS="`${XMINGW}/cross --cflags`" \
	LDFLAGS="`${XMINGW}/cross --ldflags` \
	-Wl,-s" \
	CFLAGS="-pipe -O2 -fomit-frame-pointer -ffast-math" \
	${XMINGW}/cross-configure --prefix="${INSTALL_TARGET}" --enable-iconv --enable-libxml2 --with-arch=mingw32 
}

post_configure() {
	# [2.11.0] test/test-migration.c が面倒なので test を外す。
	sed -i.orig -e's/\(^\s\+conf.d \)test /\1/' Makefile
	# [2.12.3] gperf 3.0.4 で生成したファイル。 3.1 で生成し直す。
	mv src/fcobjshash.h src/fcobjshash.h.bak
}

run_make() {
	${XMINGW}/cross make install
}

pre_pack() {
	# ライセンスなどの情報は share/doc/<MOD>/ に入れる。
	install_license_files "${MOD}" COPYING*
}

run_pack() {
	cd "${INSTALL_TARGET}" &&
	pack_archive "${__BINZIP}" bin/*.dll etc share/{fontconfig,xml} share/doc/${MOD}/COPYING &&
	pack_archive "${__DEVZIP}" include lib/*.{a,def} lib/pkgconfig &&
	pack_archive "${__DOCZIP}" share/doc share/man/man{3,5} &&
	pack_archive "${__TOOLSZIP}" bin/*.{exe,manifest,local} share/man/man1 &&
	store_packed_archive "${__BINZIP}" &&
	store_packed_archive "${__DEVZIP}" &&
	store_packed_archive "${__DOCZIP}" &&
	store_packed_archive "${__TOOLSZIP}"
}



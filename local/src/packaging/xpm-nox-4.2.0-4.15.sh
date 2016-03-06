#!/bin/bash
# vim: tabstop=4 fileformat=unix fileencoding=utf-8 filetype=sh

# license: Apatche v2.0

if [ "" = "${IN_PACKAGE_SCRIPT}" ]
then
	echo FAIL: \${XMINGW}/package から実行してください。
	exit 1
fi

# http://sourceforge.net/projects/gimp-win/files/GIMP%20%2B%20GTK%2B%20%28development%20rel.%29/GIMP%202.6.9%20%28combined%2032%2B64-bit%20installer%29/
# bsdtar -zxf mingw32-xpm-nox-4.2.0-4.15.src.rpm で
# xpm-nox-4.2.0.tar.bz2 と
# xpm-nox-4.2.0-mingw.patch を取り出しておく。


# ARCH は package が設定している。
# XLIBRARY_SOURCES は xmingw のための環境変数。 env.sh で設定している。
init_var() {
	# package に返す変数。
	MOD=xpm-nox
	[ "" = "${VER}" ] && VER=4.2.0
	[ "" = "${REV}" ] && REV=1
	DIRECTORY="${MOD}-${VER}"

	# 内部で使用する変数。

	__ARCHIVEDIR="${XLIBRARY_SOURCES}/libs/pic"
	__ARCHIVE="${MOD}-${VER}"
	__PATCH_ARCHIVE="${MOD}-${VER}-mingw.patch"

	__BINZIP=${MOD}-${VER}-${REV}-bin_${ARCHSUFFIX}
	__DEVZIP=${MOD}-dev-${VER}-${REV}_${ARCHSUFFIX}
	__TOOLSZIP=${MOD}-${VER}-${REV}-tools_${ARCHSUFFIX}
}

dependencies() {
	cat <<EOS
EOS
}

optional_dependencies() {
	cat <<EOS
EOS
}

license() {
	cat <<EOS
XPM LICENSE

EOS
}

run_expand_archive() {
local name
	name=`find_archive "${__ARCHIVEDIR}" ${__ARCHIVE}` &&
	expand_archive "${__ARCHIVEDIR}/${name}"
}

run_patch() {
	patch_adhoc -p 1 -i "${__ARCHIVEDIR}/${__PATCH_ARCHIVE}" &&
	# openSUSE Build Service のパッチを使用する場合は下記パッチは必要ない。
	patch_adhoc -p 1 <<\EOF
--- xpm-nox-4.2.0.orig/lib/misc.c
+++ xpm-nox-4.2.0/lib/misc.c
@@ -79,8 +79,7 @@
  * Function returning a character string related to an error code.
  */
 char *
-XpmGetErrorString(errcode)
-    int errcode;
+XpmGetErrorString(int errcode)
 {
     switch (errcode) {
     case XpmColorError:
EOF
}

run_make() {
	${XMINGW}/cross make all install \
	CC="gcc `${XMINGW}/cross --archcflags`" \
	CPPFLAGS="`${XMINGW}/cross --cflags`" \
	LDFLAGS="`${XMINGW}/cross --ldflags` \
	-Wl,--enable-auto-image-base -Wl,-s" \
	CFLAGS="-pipe -O2 -fomit-frame-pointer -ffast-math" \
	prefix="${INSTALL_TARGET}"
}

run_pack() {
	cd "${INSTALL_TARGET}" &&
	pack_archive "${__BINZIP}" bin/*.dll &&
	pack_archive "${__DEVZIP}" include lib/*.{def,a} &&
	pack_archive "${__TOOLSZIP}" bin/*.{exe,manifest,local} share/man/man1 &&
	store_packed_archive "${__BINZIP}" &&
	store_packed_archive "${__DEVZIP}" &&
	store_packed_archive "${__TOOLSZIP}"
}




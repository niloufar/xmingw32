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
	XLIBRARY_SET=${XLIBRARY}/gimp_build_set

	# package に返す変数。
	MOD=librsvg
	if [ "" = "${VER}" ]
	then
	VER=2.40.0
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
cairo
glib
gdk-pixbuf
libxml2
pango
EOS
}

optional_dependencies() {
	cat <<EOS
gtk+
EOS
}


run_expand_archive() {
local name
	name=`find_archive "${__ARCHIVEDIR}" ${__ARCHIVE}` &&
	expand_archive "${__ARCHIVEDIR}/${name}"
}

run_patch() {
	patch --batch -p 1 <<EOS
--- librsvg-2.40.0.orig/rsvg-base.c
+++ librsvg-2.40.0/rsvg-base.c
@@ -55,6 +55,42 @@
 #include "rsvg-paint-server.h"
 #include "rsvg-xml.h"
 
+#if defined(_WIN32) && ! defined(canonicalize_file_name)
+#include <shlwapi.h>
+TCHAR* canonicalize_file_name(const TCHAR* i_path)
+{
+TCHAR*	lpStr = NULL;
+BOOL	valid = TRUE;
+
+	lpStr = (TCHAR*) malloc( MAX_PATH * sizeof(TCHAR) );
+
+	if ( PathIsUNC( i_path ) )
+	{
+		// UNC path
+		StrCpyN( lpStr, i_path, MAX_PATH );
+	}
+	else if ( ! PathCanonicalize( lpStr, i_path ) )
+	{
+		valid = FALSE;
+	}
+
+	if ( valid && ! PathFileExists( lpStr ) )
+	{
+		valid = FALSE;
+	}
+
+	if ( ! valid )
+	{
+		if ( lpStr )
+		{
+			free( lpStr );
+		}
+		lpStr = NULL;
+	}
+	return lpStr;
+}
+#endif
+
 /*
  * This is configurable at runtime
  */
EOS
}

run_configure() {
	CC="gcc `${XMINGW}/cross --archcflags`" \
	CPPFLAGS="`${XMINGW}/cross --cflags`" \
	LDFLAGS="`${XMINGW}/cross --ldflags` \
	`${XMINGW}/cross pkg-config --libs gmodule-2.0` \
	-lshlwapi \
	-Wl,--enable-auto-image-base -Wl,-s" \
	CFLAGS="-pipe -O2 -fomit-frame-pointer -ffast-math" \
	${XMINGW}/cross-configure  --enable-shared --disable-static --prefix="${INSTALL_TARGET}" --disable-gtk-doc-html --disable-introspection
}

run_make() {
	${XMINGW}/cross make all install
}

run_pack() {
	cd "${INSTALL_TARGET}" &&
	pack_archive "${__BINZIP}" bin/*.dll `find lib -name \*.dll` &&
	pack_archive "${__DEVZIP}" include `find lib -name \*.a` lib/pkgconfig share/gtk-doc &&
	pack_archive "${__TOOLSZIP}" bin/*.{exe,manifest,local} share/man/man1 &&
	store_packed_archive "${__BINZIP}" &&
	store_packed_archive "${__DEVZIP}" &&
	store_packed_archive "${__TOOLSZIP}"
}



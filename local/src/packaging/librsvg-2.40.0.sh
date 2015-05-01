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
	# 2.40.9 で以下のパッチは必要なくなった。
	if grep rsvg-base.c -e rsvg_realpath_utf8 > /dev/null
	then
		return 0
	fi
	# 2.40.3 の不備。
	patch_adhoc -p 1 <<EOS
--- librsvg-2.40.3.orig/rsvg-convert.c
+++ librsvg-2.40.3/rsvg-convert.c
@@ -36,7 +36,11 @@
 #include <locale.h>
 #include <glib/gi18n.h>
 #include <gio/gio.h>
+#if defined(_WIN32)
+#include <gio/gwin32inputstream.h>
+#else
 #include <gio/gunixinputstream.h>
+#endif
 
 #include "rsvg-css.h"
 #include "rsvg.h"
@@ -213,7 +217,11 @@
 
         if (using_stdin) {
             file = NULL;
+#if defined(_WIN32)
+            stream = g_win32_input_stream_new (STDIN_FILENO, FALSE);
+#else
             stream = g_unix_input_stream_new (STDIN_FILENO, FALSE);
+#endif
         } else {
             file = g_file_new_for_commandline_arg (args[i]);
             stream = (GInputStream *) g_file_read (file, NULL, &error);
EOS

	# windows に realpath, canonicalize_file_name はない。
	patch_adhoc -p 1 <<EOS
--- librsvg-2.40.0.orig/rsvg-base.c
+++ librsvg-2.40.0/rsvg-base.c
@@ -57,6 +57,56 @@
 #include "rsvg-paint-server.h"
 #include "rsvg-xml.h"
 
+#if defined(_WIN32) && ! defined(realpath)
+#include <shlwapi.h>
+TCHAR* realpath(const TCHAR* i_path, TCHAR* i_resolved_path)
+{
+TCHAR*	lpStr = NULL;
+BOOL	valid = TRUE;
+
+	if ( NULL == i_resolved_path )
+	{
+		lpStr = (TCHAR*) malloc( MAX_PATH * sizeof(TCHAR) );
+	}
+	else
+	{
+		lpStr = i_resolved_path;
+	}
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
+#if defined(_WIN32) && ! defined(canonicalize_file_name)
+TCHAR* canonicalize_file_name(const TCHAR* i_path)
+{
+	return realpath( i_path, NULL );
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



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
	MOD=gdk-pixbuf
	[ "" = "${VER}" ] && VER=2.36.5
	[ "" = "${REV}" ] && REV=1
	DIRECTORY="${MOD}-${VER}"

	# 内部で使用する変数。
	__ARCHIVEDIR="${XLIBRARY_SOURCES}/gtk+"
	__ARCHIVE="${MOD}-${VER}"

	__BINZIP=${MOD}-${VER}-${REV}-bin_${ARCHSUFFIX}
	__DEVZIP=${MOD}-dev-${VER}-${REV}_${ARCHSUFFIX}
	__DOCZIP=${MOD}-doc-${VER}-${REV}_${ARCHSUFFIX}
	__TOOLSZIP=${MOD}-${VER}-${REV}-tools_${ARCHSUFFIX}
}

dependencies() {
	cat <<EOS
gettext-runtime
glib
libiconv
EOS
}

optional_dependencies() {
	cat <<EOS
jasper
libjpeg
libpng
tiff
EOS
}


run_expand_archive() {
local name
	name=`find_archive "${__ARCHIVEDIR}" ${__ARCHIVE}` &&
	expand_archive "${__ARCHIVEDIR}/${name}"
}

run_patch() {
	# [2.36.5] loaders.cache の pixbufloader のパスを、絶対パスではなく
	# dll のトップレベルパスで指定できるようにする。
	# GDK_PIXBUF_TOPLEVEL/lib のように記述すれば置き換えられる。
	# 公式には configure --prefix のパスを設定することで同様の処理が行われる。
	patch_adhoc -p 1 <<\EOS
--- gdk-pixbuf-2.36.5.orig/gdk-pixbuf/gdk-pixbuf-io.c
+++ gdk-pixbuf-2.36.5/gdk-pixbuf/gdk-pixbuf-io.c
@@ -371,6 +371,16 @@
       *path = g_strconcat (gdk_pixbuf_get_toplevel (), tem + strlen (GDK_PIXBUF_PREFIX), NULL);
       g_free (tem);
     }
+
+#define GDK_PIXBUF_TOPLEVEL "GDK_PIXBUF_TOPLEVEL"
+  if (strncmp (*path, GDK_PIXBUF_TOPLEVEL "/", strlen (GDK_PIXBUF_TOPLEVEL "/")) == 0 ||
+      strncmp (*path, GDK_PIXBUF_TOPLEVEL "\\", strlen (GDK_PIXBUF_TOPLEVEL "\\")) == 0)
+    {
+          gchar *tem = NULL;
+      tem = *path;
+      *path = g_strconcat (gdk_pixbuf_get_toplevel (), tem + strlen (GDK_PIXBUF_TOPLEVEL), NULL);
+      g_free (tem);
+    }
 }
 
 #endif  /* GDK_PIXBUF_RELOCATABLE */

--- gdk-pixbuf-2.36.5.orig/gdk-pixbuf/queryloaders.c
+++ gdk-pixbuf-2.36.5/gdk-pixbuf/queryloaders.c
@@ -150,6 +150,9 @@
 query_module (GString *contents, const char *dir, const char *file)
 {
         char *path;
+#ifdef GDK_PIXBUF_RELOCATABLE
+        char *path_orig = NULL;
+#endif /* #ifdef GDK_PIXBUF_RELOCATABLE */
         GModule *module;
         void                    (*fill_info)     (GdkPixbufFormat *info);
         void                    (*fill_vtable)   (GdkPixbufModule *module);
@@ -168,6 +171,22 @@
                 GdkPixbufFormat *info;
                 GdkPixbufModule *vtable;
 
+#ifdef GDK_PIXBUF_RELOCATABLE
+                gchar *toplevel = NULL;
+                size_t toplevel_len = 0;
+
+                toplevel = gdk_pixbuf_get_toplevel ();
+                toplevel_len = strlen(toplevel);
+                if (strncmp (path, toplevel, toplevel_len) == 0 && (
+                      strncmp ( path + toplevel_len, "/", 1) == 0 ||
+                      strncmp ( path + toplevel_len, "\\", 1) == 0))
+                  {
+                  path_orig = path;
+#define GDK_PIXBUF_TOPLEVEL "GDK_PIXBUF_TOPLEVEL"
+                  path = g_strconcat (GDK_PIXBUF_TOPLEVEL, path_orig + toplevel_len, NULL);
+                  }
+#endif /* #ifdef GDK_PIXBUF_RELOCATABLE */
+
 #ifdef G_OS_WIN32
                 /* Replace backslashes in path with forward slashes, so that
                  * it reads in without problems.
@@ -208,6 +227,9 @@
         if (module)
                 g_module_close (module);
         g_free (path);
+#ifdef GDK_PIXBUF_RELOCATABLE
+        if (NULL != path_orig) g_free (path_orig);
+#endif /* #ifdef GDK_PIXBUF_RELOCATABLE */
 }
 
 #ifdef G_OS_WIN32
EOS
}

pre_configure() {
	# [2.36.5] gdk-pixbuf/loaders.cache がないと make でこける。
local f="gdk-pixbuf/loaders.cache"
	if [ ! -e "${f}" ]
	then
		touch "${f}"
	fi
}

run_configure() {
	CC="gcc `${XMINGW}/cross --archcflags`" \
	CPPFLAGS="`${XMINGW}/cross --cflags`" \
	LDFLAGS="`${XMINGW}/cross --ldflags` \
	-Wl,--enable-auto-image-base -Wl,-s" \
	CFLAGS="-pipe -O2 -fomit-frame-pointer -ffast-math" \
	${XMINGW}/cross-configure --disable-static --enable-shared --prefix="${INSTALL_TARGET}" --enable-relocations --with-libjasper --disable-gtk-doc --without-x11
}

post_configure() {
	# shared ファイルを作ってくれない場合の対処。
	bash ${XMINGW}/replibtool.sh shared
}

run_make() {
	${XMINGW}/cross make install
}

run_pack() {
	cd "${INSTALL_TARGET}" &&
	pack_archive "${__BINZIP}" bin/*.dll bin/gdk-pixbuf-query-loaders.exe `find lib -iname \*.dll` share/locale &&
	pack_archive "${__DEVZIP}" include `find lib -iname \*.a` lib/pkgconfig &&
	pack_archive "${__DOCZIP}" share/gtk-doc &&
	pack_archive "${__TOOLSZIP}" bin/gdk-pixbuf-{csource,pixdata,thumbnailer}.exe share/man share/thumbnailers &&
	store_packed_archive "${__BINZIP}" &&
	store_packed_archive "${__DEVZIP}" &&
	store_packed_archive "${__DOCZIP}" &&
	store_packed_archive "${__TOOLSZIP}"
}



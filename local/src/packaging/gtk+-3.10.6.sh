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
	#XLIBRARY_SET=${XLIBRARY}/gimp_build_set

	# package に返す変数。
	MOD=gtk+
	if [ "" = "${VER}" ]
	then
	VER=3.10.6
	REV=1
#	PATCH=2.debian
	fi
	DIRECTORY="${MOD}-${VER}"

	# 内部で使用する変数。
	__ARCHIVEDIR="${XLIBRARY_SOURCES}/gtk+"
	__ARCHIVE="${MOD}-${VER}"
#	__PATCH_ARCHIVE="${MOD}_${VER}-${PATCH}"

	__BINZIP=${MOD}-${VER}-${REV}-bin_${ARCHSUFFIX}
	__DEVZIP=${MOD}-dev-${VER}-${REV}_${ARCHSUFFIX}
	__TOOLSZIP=${MOD}-${VER}-${REV}-tools_${ARCHSUFFIX}
}

dependencies() {
	cat <<EOS
atk
cairo
gdk-pixbuf
gettext-runtime
glib
pango
EOS
}

optional_dependencies() {
	cat <<EOS
EOS
}

license() {
	cat <<EOS
GNU LIBRARY GENERAL PUBLIC LICENSE
Version 2, June 1991
EOS
}

run_expand_archive() {
local name
	name=`find_archive "${__ARCHIVEDIR}" ${__ARCHIVE}` &&
	expand_archive "${__ARCHIVEDIR}/${name}"
}

run_patch() {
	# .symboles ファイルを使用しない関数のエクスポートに対処する。
	# 3.9.2 で行われた変更の不備。
	patch --batch --quiet -p 1 <<\EOS
--- gtk+-3.10.6.orig/gdk/Makefile.in
+++ gtk+-3.10.6/gdk/Makefile.in
@@ -94,7 +94,7 @@
 @USE_WIN32_FALSE@	$(am__append_1) $(am__append_3) \
 @USE_WIN32_FALSE@	$(am__append_5) $(am__append_7) \
 @USE_WIN32_FALSE@	$(am__append_8)
-@USE_WIN32_TRUE@am__append_6 = -Wl,win32/rc/gdk-win32-res.o -export-symbols $(srcdir)/gdk.def
+@USE_WIN32_TRUE@am__append_6 = -Wl,win32/rc/gdk-win32-res.o
 @USE_BROADWAY_TRUE@am__append_7 = broadway/libgdk-broadway.la
 @USE_WAYLAND_TRUE@am__append_8 = wayland/libgdk-wayland.la
 @HAVE_INTROSPECTION_TRUE@am__append_9 = Gdk-3.0.gir
@@ -737,7 +737,7 @@
 libgdk_3_la_LIBADD = $(GDK_DEP_LIBS) $(am__append_1) $(am__append_3) \
 	$(am__append_5) $(am__append_7) $(am__append_8)
 libgdk_3_la_LDFLAGS = $(LDADD) $(am__append_6)
-@USE_WIN32_TRUE@libgdk_3_la_DEPENDENCIES = win32/libgdk-win32.la win32/rc/gdk-win32-res.o gdk.def
+@USE_WIN32_TRUE@libgdk_3_la_DEPENDENCIES = win32/libgdk-win32.la win32/rc/gdk-win32-res.o
 @HAVE_INTROSPECTION_TRUE@introspection_files = \
 @HAVE_INTROSPECTION_TRUE@	$(filter-out gdkkeysyms-compat.h, $(gdk_public_h_sources))	\
 @HAVE_INTROSPECTION_TRUE@	$(gdk_c_sources)	\
@@ -1625,16 +1625,8 @@
 
 @HAVE_INTROSPECTION_TRUE@@USE_X11_TRUE@GdkX11-3.0.gir: libgdk-3.la Gdk-3.0.gir Makefile
 
-@OS_WIN32_TRUE@install-def-file: gdk.def
-@OS_WIN32_TRUE@	mkdir -p $(DESTDIR)$(libdir)
-@OS_WIN32_TRUE@	$(INSTALL) $(srcdir)/gdk.def $(DESTDIR)$(libdir)/gdk-win32-3.0.def
-@OS_WIN32_TRUE@uninstall-def-file:
-@OS_WIN32_TRUE@	-rm $(DESTDIR)$(libdir)/gdk-win32-3.0.def
-@OS_WIN32_FALSE@install-def-file:
-@OS_WIN32_FALSE@uninstall-def-file:
-
-@MS_LIB_AVAILABLE_TRUE@gdk-win32-$(GTK_API_VERSION).lib: libgdk-win32-$(GTK_API_VERSION).la gdk.def
-@MS_LIB_AVAILABLE_TRUE@	lib -machine:@LIB_EXE_MACHINE_FLAG@ -name:libgdk-win32-$(GTK_API_VERSION)-@LT_CURRENT_MINUS_AGE@.dll -def:gdk.def -out:$@
+@MS_LIB_AVAILABLE_TRUE@gdk-win32-$(GTK_API_VERSION).lib: libgdk-win32-$(GTK_API_VERSION).la
+@MS_LIB_AVAILABLE_TRUE@	lib -machine:@LIB_EXE_MACHINE_FLAG@ -name:libgdk-win32-$(GTK_API_VERSION)-@LT_CURRENT_MINUS_AGE@.dll -out:$@
 
 @MS_LIB_AVAILABLE_TRUE@install-ms-lib:
 @MS_LIB_AVAILABLE_TRUE@	mkdir -p $(DESTDIR)$(libdir)
@@ -1714,9 +1706,9 @@
 	$(CPP) -P - <$(top_srcdir)/build/win32/vs10/gdk.vcxproj.filtersin >$@
 	rm libgdk.vs10.sourcefiles.filters
 
-install-data-local: install-ms-lib install-def-file
+install-data-local: install-ms-lib
 
-uninstall-local: uninstall-ms-lib uninstall-def-file
+uninstall-local: uninstall-ms-lib
 	rm -f $(DESTDIR)$(configexecincludedir)/gdkconfig.h
 
 # if srcdir!=builddir, clean out maintainer-clean files from builddir
--- gtk+-3.10.6.orig/gtk/Makefile.in
+++ gtk+-3.10.6/gtk/Makefile.in
@@ -1047,8 +1047,6 @@
 	$(INCLUDED_IMMODULE_DEFINE)
 
 @PLATFORM_WIN32_TRUE@no_undefined = -no-undefined
-@OS_WIN32_TRUE@gtk_def = gtk.def
-@OS_WIN32_TRUE@gtk_win32_symbols = -export-symbols $(srcdir)/gtk.def
 @OS_WIN32_TRUE@gtk_win32_res = gtk-win32-res.o
 @OS_WIN32_TRUE@gtk_win32_res_ldflag = -Wl,gtk-win32-res.o
 @MS_LIB_AVAILABLE_TRUE@noinst_DATA = gtk-win32-$(GTK_API_VERSION).lib
@@ -1959,7 +1957,7 @@
 libgtk_3_la_LDFLAGS = $(libtool_opts) $(am__append_15)
 libgtk_3_la_LIBADD = $(libadd) $(am__append_14)
 libgtk_3_la_DEPENDENCIES = $(deps) $(am__append_16)
-@USE_WIN32_TRUE@libgtk_target_ldflags = $(gtk_win32_res_ldflag) $(gtk_win32_symbols)
+@USE_WIN32_TRUE@libgtk_target_ldflags = $(gtk_win32_res_ldflag)
 DEPS = libgtk-3.la $(top_builddir)/gdk/libgdk-3.la
 TEST_DEPS = $(DEPS) immodules.cache
 LDADDS = \
@@ -5912,15 +5910,8 @@
 @OS_WIN32_TRUE@gtk-win32-res.o : gtk-win32.rc
 @OS_WIN32_TRUE@	$(WINDRES) gtk-win32.rc $@
 
-@OS_WIN32_TRUE@install-def-file: gtk.def
-@OS_WIN32_TRUE@	$(INSTALL) $(srcdir)/gtk.def $(DESTDIR)$(libdir)/gtk-win32-3.0.def
-@OS_WIN32_TRUE@uninstall-def-file:
-@OS_WIN32_TRUE@	-rm $(DESTDIR)$(libdir)/gtk-win32-3.0.def
-@OS_WIN32_FALSE@install-def-file:
-@OS_WIN32_FALSE@uninstall-def-file:
-
-@MS_LIB_AVAILABLE_TRUE@gtk-win32-$(GTK_API_VERSION).lib: libgtk-win32-$(GTK_API_VERSION).la gtk.def
-@MS_LIB_AVAILABLE_TRUE@	lib -machine:@LIB_EXE_MACHINE_FLAG@ -name:libgtk-win32-$(GTK_API_VERSION)-@LT_CURRENT_MINUS_AGE@.dll -def:gtk.def -out:$@
+@MS_LIB_AVAILABLE_TRUE@gtk-win32-$(GTK_API_VERSION).lib: libgtk-win32-$(GTK_API_VERSION).la
+@MS_LIB_AVAILABLE_TRUE@	lib -machine:@LIB_EXE_MACHINE_FLAG@ -name:libgtk-win32-$(GTK_API_VERSION)-@LT_CURRENT_MINUS_AGE@.dll -out:$@
 
 @MS_LIB_AVAILABLE_TRUE@install-ms-lib:
 @MS_LIB_AVAILABLE_TRUE@	$(INSTALL) gtk-win32-$(GTK_API_VERSION).lib $(DESTDIR)$(libdir)
@@ -6055,13 +6046,13 @@
 	rm libgtk.vs10.sourcefiles.filters
 
 # Install a RC file for the default GTK+ theme, and key themes
-install-data-local: install-ms-lib install-def-file install-mac-key-theme
+install-data-local: install-ms-lib install-mac-key-theme
 	$(MKDIR_P) $(DESTDIR)$(datadir)/themes/Default/gtk-3.0
 	$(INSTALL_DATA) $(srcdir)/gtk-keys.css.default $(DESTDIR)$(datadir)/themes/Default/gtk-3.0/gtk-keys.css
 	$(MKDIR_P) $(DESTDIR)$(datadir)/themes/Emacs/gtk-3.0
 	$(INSTALL_DATA) $(srcdir)/gtk-keys.css.emacs $(DESTDIR)$(datadir)/themes/Emacs/gtk-3.0/gtk-keys.css
 
-uninstall-local: uninstall-ms-lib uninstall-def-file uninstall-mac-key-theme
+uninstall-local: uninstall-ms-lib uninstall-mac-key-theme
 	rm -f $(DESTDIR)$(datadir)/themes/Raleigh/gtk-3.0/gtk.css
 	rm -f $(DESTDIR)$(datadir)/themes/Default/gtk-3.0/gtk-keys.css
 	rm -f $(DESTDIR)$(datadir)/themes/Emacs/gtk-3.0/gtk-keys.css
EOS
}

run_configure() {
	# ビルドに gtk-update-icon-cache, gtk-query-immodules-3.0 が必要。
	# ない場合は apt-get install libgtk-3-dev しておく。
	# --enable_gtk2_dependency を付けなければ gtk/native の native-update-icon-cache をビルドする。
	# しかし不備があり、
	#  CFLAGS, CPPFLAGS, LDFLAGS, EXEEXT が _FOR_BUILD ではなく、
	#  xcompile のものを使用する。
	# libtool を使用するのもよろしくない。
	CC="gcc `${XMINGW}/cross --archcflags`" \
	CPPFLAGS="`${XMINGW}/cross --cflags`" \
	LDFLAGS="`${XMINGW}/cross --ldflags` \
	-Wl,--enable-auto-image-base -Wl,-s" \
	CFLAGS="-pipe -O2 -fomit-frame-pointer -ffast-math  -static-libgcc" \
	CC_FOR_BUILD=build-cc \
	PKG_CONFIG_FOR_BUILD="$XMINGW/cross-host pkg-config" \
	${XMINGW}/cross-configure --disable-static  --prefix="${INSTALL_TARGET}" --enable-win32-backend --enable-gtk2-dependency --with-included-immodules
}

post_configure() {
	# 使用する場合は bash ${XMINGW}/replibtool.sh にオプションを並べる。
	# shared ファイルを作ってくれない場合の対処。
	bash ${XMINGW}/replibtool.sh shared
}

run_make() {
	${XMINGW}/cross make gtk_def= gdk_def= all install
}

run_pack() {
	cd "${INSTALL_TARGET}" &&
	pack_archive "${__BINZIP}" bin/*.dll etc `find lib -name \*.dll` share/{locale,themes} share/glib-2.0/schemas &&
	pack_archive "${__DEVZIP}" bin/gtk-query-immodules-3.0.exe include `find lib -name \*.def -or -name \*.a` lib/pkgconfig share/{aclocal,glib-2.0,gtk-3.0,gtk-doc} &&
	pack_archive "${__TOOLSZIP}" bin/gtk3-*.exe bin/gtk-launch.exe share/man/man1 &&
	store_packed_archive "${__BINZIP}" &&
	store_packed_archive "${__DEVZIP}" &&
	store_packed_archive "${__TOOLSZIP}"
}




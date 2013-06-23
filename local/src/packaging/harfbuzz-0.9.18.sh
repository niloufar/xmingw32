#!/bin/bash
# vim: tabstop=4 fileformat=unix fileencoding=utf-8 filetype=sh

# license: Apatche v2.0

if [ "" = "${IN_PACKAGE_SCRIPT}" ]
then
	echo FAIL: \${XMINGW}/package から実行してください。
	exit 1
fi


# ARCH は package が設定している。
# XLIBRARY_SOURCES は xmingw のための環境変数鵜。 env.sh で設定している。
init_var() {
	# package に返す変数。
	MOD=harfbuzz
	if [ "" = "${VER}" ]
	then
	VER=0.9.18
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
fontconfig
freetype2
glib
EOS
}

dependencies_opt() {
	cat <<EOS
EOS
}

run_expand_archive() {
local name
	name=`find_archive "${__ARCHIVEDIR}" ${__ARCHIVE}` &&
	expand_archive "${__ARCHIVEDIR}/${name}"
}

pre_configure() {
	# harfbuzz.pc で prefix 変数を参照するべきところを埋め込みにしている。
	(patch --batch --quiet -p 0 <<\EOF; return 0) &&
--- src/Makefile.in.orig
+++ src/Makefile.in
@@ -1782,9 +1782,9 @@
 	$(AM_V_GEN) \
 	cat "$<" | \
 	$(SED) -e 's@%prefix%@$(prefix)@g;' | \
-	$(SED) -e 's@%exec_prefix%@$(exec_prefix)@g;' | \
-	$(SED) -e 's@%libdir%@$(libdir)@g;' | \
-	$(SED) -e 's@%includedir%@$(includedir)@g;' | \
+	$(SED) -e 's@%exec_prefix%@$${prefix}@g;' | \
+	$(SED) -e 's@%libdir%@$${exec_prefix}/lib@g;' | \
+	$(SED) -e 's@%includedir%@$${prefix}/include@g;' | \
 	$(SED) -e 's@%VERSION%@$(VERSION)@g;' | \
 	cat > "$@.tmp" && mv "$@.tmp" "$@" || ( $(RM) "$@.tmp"; false )
 harfbuzz.def: $(HBHEADERS) $(HBNODISTHEADERS)
EOF
	# test_unicode のリンクで harfbuzz.a を渡していない。
	(patch --batch --quiet -p 0 <<\EOF; return 0)
--- test/api/Makefile.in.orig
+++ test/api/Makefile.in
@@ -145,12 +145,13 @@
 @HAVE_GLIB_TRUE@	$(am__DEPENDENCIES_1)
 test_unicode_SOURCES = test-unicode.c
 test_unicode_OBJECTS = test_unicode-test-unicode.$(OBJEXT)
+test_unicode_LDADD = $(LDADD)
 @HAVE_GLIB_TRUE@am__DEPENDENCIES_2 =  \
 @HAVE_GLIB_TRUE@	$(top_builddir)/src/libharfbuzz.la \
 @HAVE_GLIB_TRUE@	$(am__DEPENDENCIES_1)
-@HAVE_GLIB_TRUE@@HAVE_ICU_TRUE@test_unicode_DEPENDENCIES =  \
-@HAVE_GLIB_TRUE@@HAVE_ICU_TRUE@	$(am__DEPENDENCIES_2) \
-@HAVE_GLIB_TRUE@@HAVE_ICU_TRUE@	$(top_builddir)/src/libharfbuzz-icu.la
+@HAVE_GLIB_TRUE@HAVE_ICU_TRUE@test_unicode_DEPENDENCIES =  \
+@HAVE_GLIB_TRUE@HAVE_ICU_TRUE@	$(am__DEPENDENCIES_2) \
+@HAVE_GLIB_TRUE@HAVE_ICU_TRUE@	$(top_builddir)/src/libharfbuzz-icu.la
 test_version_SOURCES = test-version.c
 test_version_OBJECTS = test-version.$(OBJEXT)
 test_version_LDADD = $(LDADD)
EOF
}

# XP のための特別な処理。
run_configure_xp() {
	CC="gcc `${XMINGW}/cross --archcflags`" \
	CPPFLAGS="`${XMINGW}/cross --cflags`" \
	LDFLAGS="`${XMINGW}/cross --ldflags` \
	-Wl,--enable-auto-image-base -Wl,-s" \
	CFLAGS="-pipe -O2 -fomit-frame-pointer -ffast-math" \
	${XMINGW}/cross-configure --disable-shared --enable-static --prefix="${INSTALL_TARGET}" --with-uniscribe=no
}

run_configure() {
	CC="gcc `${XMINGW}/cross --archcflags`" \
	CPPFLAGS="`${XMINGW}/cross --cflags`" \
	LDFLAGS="`${XMINGW}/cross --ldflags` \
	-Wl,--enable-auto-image-base -Wl,-s" \
	CFLAGS="-pipe -O2 -fomit-frame-pointer -ffast-math" \
	${XMINGW}/cross-configure --disable-shared --enable-static --prefix="${INSTALL_TARGET}" --with-uniscribe=auto
}

run_make() {
	${XMINGW}/cross make all install
}

pre_pack() {
	(cd "${INSTALL_TARGET}/lib/pkgconfig" &&
	sed -i -e's/^Libs:.\+$/\0 -lusp10 -lgdi32/' harfbuzz.pc &&
	echo "Requires: glib-2.0" >> harfbuzz.pc
	)
#	echo skip > /dev/null
}

run_pack() {
	cd "${INSTALL_TARGET}" &&
#	pack_archive "${__BINZIP}" bin/*.dll &&
	pack_archive "${__DEVZIP}" include lib/*.{def,a} lib/pkgconfig &&
	pack_archive "${__TOOLSZIP}" bin/*.{exe,manifest,local} &&
#	store_packed_archive "${__BINZIP}" &&
	store_packed_archive "${__DEVZIP}" &&
	store_packed_archive "${__TOOLSZIP}"
}



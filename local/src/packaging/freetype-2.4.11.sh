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
	MOD=freetype
	if [ "" = "${VER}" ]
	then
	VER=2.4.11
	REV=1
	fi
	DIRECTORY="${MOD}-${VER}"

	# 内部で使用する変数。
	__ARCHIVEDIR="${XLIBRARY_SOURCES}/libs/pic"
	__ARCHIVE="${MOD}-${VER}"

	__BINZIP=${MOD}-${VER}-${REV}-bin_${ARCHSUFFIX}
	__DEVZIP=${MOD}-dev-${VER}-${REV}_${ARCHSUFFIX}
#	__TOOLSZIP=${MOD}-${VER}-${REV}-tools_${ARCHSUFFIX}
}

dependencies() {
	cat <<EOS
zlib
EOS
}


run_expand_archive() {
local name
	name=`find_archive "${__ARCHIVEDIR}" ${__ARCHIVE}` &&
	expand_archive "${__ARCHIVEDIR}/${name}"
}

# 2.5.0.1 の問題に対処する。
pre_configure() {
	(patch --batch --quiet -p 0 <<\EOF; return 0)
--- builds/unix/unix-def.in.orig
+++ builds/unix/unix-def.in
@@ -103,10 +103,10 @@
 	    -e 's|%LIBBZ2%|$(LIBBZ2)|' \
 	    -e 's|%LIBZ%|$(LIBZ)|' \
 	    -e 's|%build_libtool_libs%|$(build_libtool_libs)|' \
-	    -e 's|%exec_prefix%|$(exec_prefix)|' \
+	    -e 's|%exec_prefix%|$${prefix}|' \
 	    -e 's|%ft_version%|$(ft_version)|' \
-	    -e 's|%includedir%|$(includedir)|' \
-	    -e 's|%libdir%|$(libdir)|' \
+	    -e 's|%includedir%|$${prefix}/include|' \
+	    -e 's|%libdir%|$${exec_prefix}/lib|' \
 	    -e 's|%prefix%|$(prefix)|' \
 	    $< \
 	    > $@.tmp
@@ -120,10 +120,10 @@
 	    -e 's|%LIBBZ2%|$(LIBBZ2)|' \
 	    -e 's|%LIBZ%|$(LIBZ)|' \
 	    -e 's|%build_libtool_libs%|$(build_libtool_libs)|' \
-	    -e 's|%exec_prefix%|$(exec_prefix)|' \
+	    -e 's|%exec_prefix%|$${prefix}|' \
 	    -e 's|%ft_version%|$(ft_version)|' \
-	    -e 's|%includedir%|$(includedir)|' \
-	    -e 's|%libdir%|$(libdir)|' \
+	    -e 's|%includedir%|$${prefix}/include|' \
+	    -e 's|%libdir%|$${exec_prefix}/lib|' \
 	    -e 's|%prefix%|$(prefix)|' \
 	    $< \
 	    > $@.tmp
EOF
}

run_configure() {
	CC="gcc `${XMINGW}/cross --archcflags`" \
	CC_BUILD=build-cc \
	CPPFLAGS="`${XMINGW}/cross --cflags`" \
	LDFLAGS="`${XMINGW}/cross --ldflags` \
	-Wl,--enable-auto-image-base -Wl,-s" \
	CFLAGS="-pipe -O2 -fomit-frame-pointer -ffast-math" \
	LIBPNG_CFLAGS="`${XMINGW}/cross libpng-config --cflags`" \
	LIBPNG_LDFLAGS="`${XMINGW}/cross libpng-config --ldflags`" \
	${XMINGW}/cross-configure --disable-static --prefix="${INSTALL_TARGET}"
}

post_configure() {
	# freetype6.dll の形にするため書き換える。
	sed -i.orig -e 's#^soname_spec=.*#soname_spec="\\\`echo "\\\${libname}\\\${versuffix}" | \\\$SED -e "s/^lib//" -e "s/-//"\\\`\\\${shared_ext}"#' builds/unix/libtool
}

run_make() {
	${XMINGW}/cross make all install
}

pre_pack() {
	# スクリプト内の prefix を置き換える。
	sed -i -e 's#^\(prefix=\).*#\1\`dirname \$0\`/..#' "${INSTALL_TARGET}/bin/freetype-config"
}

run_pack() {
	cd "${INSTALL_TARGET}" &&
	pack_archive "${__BINZIP}" bin/*.dll &&
	pack_archive "${__DEVZIP}" bin/*-config include lib/*.a lib/pkgconfig share/aclocal &&
	store_packed_archive "${__BINZIP}" &&
	store_packed_archive "${__DEVZIP}"
}



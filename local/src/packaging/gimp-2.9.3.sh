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
	# cross に渡す変数。
	XLIBRARY_SET=${XLIBRARY}/gimp_build_set

	# package に返す変数。
	MOD=gimp
	if [ "" = "${VER}" ]
	then
	VER=2.9.3pre
	REV=1
	fi
	DIRECTORY="${MOD}-${VER}"

	# 内部で使用する変数。
	__ARCHIVEDIR="${XLIBRARY_SOURCES}/gimp/core"
	__ARCHIVE="${MOD}-${VER}"

	__BINZIP=${MOD}-${VER}-${REV}-bin_${ARCHSUFFIX}
	__DEVZIP=${MOD}-dev-${VER}-${REV}_${ARCHSUFFIX}
#	__TOOLSZIP=${MOD}-${VER}-${REV}-tools_${ARCHSUFFIX}
}

# INSTALL と configure.ac を参考にした。
dependencies() {
	cat <<EOS
babl
cairo
fontconfig
freetype2
gdk-pixbuf
gegl
gettext-runtime
glib
gtk+
libiconv
libmypaint
pango
EOS
}

optional_dependencies() {
	cat <<EOS
bzip2
lcms
libexif
libjpeg
libmng
libpng
librsvg
libwmf
libxml2
python
tiff
xpm-nox
zlib
EOS
}

license() {
	cat <<EOS
GNU GENERAL PUBLIC LICENSE
Version 3, 29 June 2007
GNU LESSER GENERAL PUBLIC LICENSE
Version 3, 29 June 2007
EOS
}

run_expand_archive() {
local name
	name=`find_archive "${__ARCHIVEDIR}" ${__ARCHIVE}` &&
	expand_archive "${__ARCHIVEDIR}/${name}"
}

run_patch() {
	# libwmf が -lpng 決め打ちしているのでごまかす。
	# 下は libpng16 を設定している。場所は ${XLIBRARY}/lib 
	mkdir -p libpng &&
	ln -f -s ${XLIBRARY}/lib/include/libpng16 libpng/include &&
	mkdir -p libpng/lib &&
	ln -f -s ${XLIBRARY}/lib/lib/libpng16.dll.a libpng/lib/libpng.dll.a &&
	mkdir -p "${INSTALL_TARGET}" &&
	# ファイル パスに GIMP_APP_VERSION が含まれていた場合に発生する不具合への対処。
	patch_adhoc -p 1 <<EOS
--- gimp-2.8.4.orig/app/core/gimp-user-install.c
+++ gimp-2.8.4/app/core/gimp-user-install.c
@@ -226,7 +226,11 @@
   gchar    *version;
   gboolean  migrate = FALSE;
 
-  version = strstr (dir, GIMP_APP_VERSION);
+  version = strstr (dir, ".gimp-" GIMP_APP_VERSION);
+  if (version)
+    {
+      version = strstr (version, GIMP_APP_VERSION);
+    }
 
   if (version)
     {
EOS
}

pre_configure() {
	if [ ! -e "./configure" ]
	then
		NOCONFIGURE=1 $XMINGW/cross-host sh ./autogen.sh --disable-gtk-doc --disable-dependency-tracking
	fi
}

run_configure() {
	# _WIN32_WINNT=0x0503 は XP SP3 （推測）
	# little cms の問題で -Dcdecl=LCMSAPI している。
	# ${PWD}/libpng/lib をリンク パスにいれてくれない。
	CC="gcc `${XMINGW}/cross --archcflags`" \
	CPPFLAGS="`${XMINGW}/cross --cflags` \
	-Dcdecl=LCMSAPI \
	-DWINVER=0x0503 -D_WIN32_WINNT=0x0503 -DXPM_NO_X \
	-I${XLIBRARY}/gimp-dep/include/noX" \
	LDFLAGS="`${XMINGW}/cross --ldflags` \
	-Wl,--enable-auto-image-base \
	-L${PWD}/libpng/lib \
	-lgdi32 -lwsock32 -lole32 -Wl,-s" \
	CFLAGS="-pipe -O2 -fomit-frame-pointer -ffast-math" \
	${XMINGW}/cross-configure --enable-shared --disable-static --enable-mmx --enable-sse --with-directx-sdk= --disable-python --without-x --prefix="${INSTALL_TARGET}"
}

post_configure() {
	bash ${XMINGW}/replibtool.sh shared static-libgcc
}

run_make() {
	# 作成されないプラグイン file_xmc を作成しようとするので抑止している。
	${XMINGW}/cross make FILE_XMC="" all install
}

run_make_test() {
	(
	(cd app/tests && ${XMINGW}/cross make test-core.exe test-gimpidtable.exe test-save-and-export.exe test-session-2-6-compatibility.exe test-session-2-8-compatibility-multi-window.exe test-session-2-8-compatibility-single-window.exe test-single-window-mode.exe test-tools.exe test-ui.exe test-xcf.exe) &&

	TESTSZIP=${MOD}-${VER}-${REV}-tests_${ARCHSUFFIX} &&
	pack_archive "${TESTSZIP}" app/tests/*.exe app/tests/{.libs,files,gimpdir,gimpdir-empty,gimpdir-output} tools/test-clipboard.exe tools/.libs/\*test-clipboard\*
	)
	return 0
}

pre_pack() {
local files=""
	# head には ChangeLog がない。
	for f in AUTHORS COPYING ChangeLog LICENSE NEWS README
	do
		if [ -e "${f}" ]
		then
			files="${files} ${f}"
		fi
	done
	cp ${files} "${INSTALL_TARGET}/." &&
	(cd "${INSTALL_TARGET}" &&
	# 外観を windows 標準にする。
	# pango により代替フォントとして使用される arial unicode ms は品質が悪い。
	mkdir -p etc/gtk-2.0 &&
	cat <<EOF > etc/gtk-2.0/gtkrc &&
gtk-theme-name = "MS-Windows"
style "win-font"
{
#  font_name = "MS UI Gothic 9"
#  font_name = "MS Gothic 9"
#  font_name = "Meiryo UI 9"
  font_name = "Meiryo 9"
}
widget "*" style "win-font"
EOF
	# side-by-side
	echo > bin/gimp-2.8.exe.local &&
	echo > bin/gimp-console-2.8.exe.local)	
}

run_pack() {
	(cd "${INSTALL_TARGET}" &&
	pack_archive "${__BINZIP}" bin/*.{exe,dll,local} etc `find lib/gimp -xtype f -not -iname \*.a -and -not -iname \*.la` share/{gimp,icons,locale} [ACLNR]* &&
	pack_archive "${__DEVZIP}" bin/gimptool-2.0* include `find lib -xtype f -iname \*.a -or -iname \*.def` lib/pkgconfig share/{aclocal,icons} &&
	store_packed_archive "${__BINZIP}" &&
	store_packed_archive "${__DEVZIP}")
}



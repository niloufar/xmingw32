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
	# cross に渡す変数。
	XLIBRARY_SET="gtk gimp_build"

	# package に返す変数。
	MOD=gimp
	[ "" = "${VER}" ] && VER=2.9.3pre
	[ "" = "${REV}" ] && REV=1
	DIRECTORY="${MOD}-${VER}"

	# 内部で使用する変数。
	__ARCHIVEDIR="${XLIBRARY_SOURCES}/gimp/core"
	__ARCHIVE="${MOD}-${VER}"

	__BINZIP=${MOD}-${VER}-${REV}-bin_${ARCHSUFFIX}
	__DEVZIP=${MOD}-dev-${VER}-${REV}_${ARCHSUFFIX}
	__DOCZIP=${MOD}-${VER}-${REV}-doc_${ARCHSUFFIX}
#	__TOOLSZIP=${MOD}-${VER}-${REV}-tools_${ARCHSUFFIX}
}

# INSTALL と configure.ac を参考にした。
dependencies() {
	cat <<EOS
atk
babl
bzip2
cairo
fontconfig
freetype2
gdk-pixbuf
gegl
gettext-runtime
glib
gtk2
harfbuzz
lcms2
libiconv
libjpeg
libmypaint
libpng
libpoppler
libpoppler-data
librsvg
mypaint-brushes
pango
tiff
xz
zlib
EOS
}

optional_dependencies() {
	cat <<EOS
glib-networking
jasper
libaa
libexif
libheif
libmng
libwebp
libwmf
libxml2
openexr
python2
xpm-nox
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
local libwmf_png="libpng16"
	mkdir -p libpng &&
	ln -s "$(${XMINGW}/cross pkg-config --variable=includedir ${libwmf_png})" libpng/include &&
	mkdir -p libpng/lib &&
	ln -s "$(${XMINGW}/cross pkg-config --variable=libdir ${libwmf_png})/${libwmf_png}.dll.a" libpng/lib/libpng.dll.a &&
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

	# ファイル名の英大文字小文字の問題。
	patch_adhoc -p 1 <<EOS
--- gimp-git.orig/plug-ins/file-raw/file-raw-utils.c
+++ gimp-git/plug-ins/file-raw/file-raw-utils.c
@@ -27,7 +27,7 @@
 #endif
 
 #ifdef GDK_WINDOWING_WIN32
-#include <Windows.h>
+#include <windows.h>
 #endif
 
 #include <libgimp/gimp.h>
EOS

	# OpenEXR の PixelType 列挙型の列挙子の namespace 問題への対処。
#	sed -i.orig -e 's/ \(UINT\|HALF\|FLOAT\)\(,\|:\|)\)/ Imf::\1\2/' plug-ins/file-exr/openexr-wrapper.cc

	return 0
}

pre_configure() {
	if [ ! -e "./configure" ]
	then
		NOCONFIGURE=1 sh ./autogen.sh --disable-gtk-doc --disable-dependency-tracking
	fi

	# 2017/4/3mon: --enable-vector-icons のチェックがクロス コンパイルを考慮していないため強制的に有効にする。
	# 	 DirectInput も強制的に有効にする。
	# 2017/6/10sat: libmng の __stdcall 関係が面倒なため強制的に有効にする。
	# [2.10.20] NATIVE_GLIB_{LIBS,CFLAGS} を上書きしないようにする。
	sed -i.orig configure \
		-e 's/enable_vector_icons=".*"/enable_vector_icons="yes"/' \
		-e 's/^have_dx_dinput=no/have_dx_dinput=yes/' \
		-e 's/ac_cv_lib_mng_mng_create=no/ac_cv_lib_mng_mng_create=yes/' \
		-e 's/^\s\+NATIVE_GLIB_\(LIBS\|CFLAGS\)=.\+pkg-config /#\0/'

	# [2.10.14] mypaint-brush v2 系への対応。
#	sed -i.orig configure -e 's/\"mypaint-brushes-1.0\"/\"mypaint-brushes-2.0\"/'
}

run_configure() {
	# little cms の問題で -Dcdecl=LCMSAPI している。
	# ${PWD}/libpng/lib をリンク パスにいれてくれない。
	# 2017/4/1sat NATIVE_GLIB_{CFLAGS,LIBS} は invert-svg のビルドで必要になる。
	#	--disable-vector-icons では設定されないまま invert-svg をビルドする。
	CC="gcc `${XMINGW}/cross --archcflags`" \
	CPPFLAGS="`${XMINGW}/cross --cflags` \
	-Dcdecl=LCMSAPI \
	-DMNG_USE_DLL \
	-DWINVER=_WIN32_WINNT_VISTA -D_WIN32_WINNT=_WIN32_WINNT_VISTA \
	-DXPM_NO_X -I${XLIBRARY}/gimp-dep/include/noX" \
	LDFLAGS="`${XMINGW}/cross --ldflags` \
	-Wl,--enable-auto-image-base \
	-L${PWD}/libpng/lib \
	-lgdi32 -lwsock32 -lole32 -Wl,-s" \
	CFLAGS="-pipe -O2 -fomit-frame-pointer -ffast-math" \
	${XMINGW}/cross-configure --enable-shared --disable-static --prefix="${INSTALL_TARGET}" \
		--enable-relocatable-bundle \
		--enable-mmx --enable-sse \
		--disable-python --without-python \
		--without-javascript --without-lua \
		--enable-vala=yes \
		--without-x \
		--with-libjasper --with-libmng --with-librsvg --with-libxpm \
		--without-openexr --without-xmc \
		--with-webp --with-wmf --with-cairo-pdf --with-poppler \
		--without-libbacktrace --without-libunwind --without-webkit \
		--without-appstream-glib --without-libarchive \
		--with-print --with-directx-sdk="" \
		--disable-check-update \
		CC_FOR_BUILD="$XMINGW/cross-host gcc" \
		NATIVE_GLIB_CFLAGS="`$XMINGW/cross-host pkg-config g{lib,io}-2.0 --cflags`" \
		NATIVE_GLIB_LIBS="`$XMINGW/cross-host pkg-config g{lib,io}-2.0 --libs`" \
		--enable-vector-icons
}

post_configure() {
	# [2018/2/6tue] git-version.h へのインクルード パスが設定されていない。
	ln -s $PWD/git-version.h $PWD/build/windows/git-version.h

	bash ${XMINGW}/replibtool.sh shared static-libgcc

	# [2.99.6] いくつかライブラリーがリンクされない。
	case "${VER}" in
	2.99.6)
		sed -i.orig libgimp/Makefile \
			-e '/^libgimp_3.0_la_LIBADD/,/^$/ {' \
				-e '/$(RT_LIBS)/i\  $(GEXIV2_LIBS)          \\' -e '}' \
			-e '/^libgimpui_3.0_la_LIBADD/,/^$/ {' \
				-e '/$(libgimpcolor)/i\  $(libgimpconfig)        \\' -e '}'
		;;
	esac
}

run_make() {
	WINEPATH="${PWD}/libgimpbase/.libs/;${PWD}/libgimpmath/.libs;${PWD}/libgimpconfig/.libs;${PWD}/libgimpcolor/.libs;${PWD}/libgimpmodule/.libs;${PWD}/libgimpwidgets/.libs;${PWD}/libgimpthumb/.libs;${PWD}/libgimp/.libs" \
	${XMINGW}/cross make all install
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

	install_license_files "libgimp" libgimp/COPYING
	install_license_files "tinyscheme" plug-ins/script-fu/tinyscheme/COPYING

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
	echo > bin/gimp-2.9.exe.local &&
	echo > bin/gimp-console-2.9.exe.local)	
}

run_pack() {
	cd "${INSTALL_TARGET}" &&
	pack_archive "${__BINZIP}" bin/*.{exe,dll,local} etc `find lib/gimp -xtype f -not -iname \*.a -and -not -iname \*.la` share/{gimp,icons,locale} share/doc [ACLNR]* &&
	pack_archive "${__DEVZIP}" bin/gimptool-2.0* include `find lib -xtype f -iname \*.a -or -iname \*.def` lib/pkgconfig share/{aclocal,icons} &&
	store_packed_archive "${__BINZIP}" &&
	store_packed_archive "${__DEVZIP}" &&

	if [[ -d "share/gtk-doc" ]]
	then
		pack_archive "${__DOCZIP}" share/gtk-doc &&
		store_packed_archive "${__DOCZIP}"
	fi &&

	put_exclude_files share/appdata share/applications/*.desktop share/man share/metainfo
}



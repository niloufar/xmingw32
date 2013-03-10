#!/bin/bash
# vim: tabstop=4 fileformat=unix fileencoding=utf-8 filetype=sh

# license: Apatche v2.0

if [ "" = "${XMINGW}" ]
then
	echo fail: XMINGW 環境で実行してください。
	exit 1
fi
. ${XMINGW}/scripts/build_lib.func


MOD=gimp
VER=2.8.4
REV=1
ARCH=win32

ARCHIVEDIR="${XLIBRARY_SOURCES}/gimp/core"
ARCHIVE="${MOD}-${VER}"
DIRECTORY="${MOD}-${VER}"

THIS=${MOD}-${VER}-${REV}_${ARCH}

BINZIP=${MOD}-${VER}-${REV}-bin_${ARCH}
DEVZIP=${MOD}-dev-${VER}-${REV}_${ARCH}
TOOLSZIP=${MOD}-${VER}-${REV}-tools_${ARCH}

HEX=`echo ${THIS} | md5sum | cut -d' ' -f1`
INSTALL_TARGET=${XLIBRARY_TEMP}/${HEX}


run_expand_archive() {
local name
	name=`find_archive "${ARCHIVEDIR}" ${ARCHIVE}` &&
	expand_archive "${ARCHIVEDIR}/${name}"
}

pre_configure() {
	echo skip > /dev/null
}

run_configure() {
	# _WIN32_WINNT=0x0503 は XP SP3 （推測）
	# little cms の問題で -Dcdecl=LCMSAPI している。
	# ${PWD}/libpng/lib をリンクパスにいれてくれない。
	CC="gcc `${XMINGW}/cross --archcflags`" \
	CPPFLAGS="`${XMINGW}/cross --cflags` \
	-Dcdecl=LCMSAPI \
	-DWINVER=0x0503 -D_WIN32_WINNT=0x0503 -DXPM_NO_X \
	-I${XLIBRARY}/gimp-dep/include/noX" \
	LDFLAGS="`${XMINGW}/cross --ldflags` \
	-Wl,--enable-auto-image-base \
	-L${PWD}/libpng/lib \
	-lwsock32 -lole32 -Wl,-s" \
	CFLAGS="-pipe -O2 -fomit-frame-pointer -ffast-math" \
	${XMINGW}/cross-configure --target=i386-pc-mingw32 --enable-shared --disable-static --enable-mmx --enable-sse --disable-python --without-x --prefix="${INSTALL_TARGET}"
}

post_configure() {
	bash ${XMINGW}/replibtool.sh &&
	# libwmf が -lpng 決め打ちしているのでごまかす。
	# 下は libpng16 を設定している。場所は ${XLIBRARY}/lib 
	mkdir -p libpng &&
	ln -f -s ${XLIBRARY}/lib/include/libpng16 libpng/include &&
	mkdir -p libpng/lib &&
	ln -f -s ${XLIBRARY}/lib/lib/libpng16.dll.a libpng/lib/libpng.dll.a &&
	mkdir -p "${INSTALL_TARGET}" &&
	# ファイルパスに GIMP_APP_VERSION が含まれていた場合に発生する不具合への対処。
	patch -p 1 <<EOS
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

pre_make() {
	echo skip > /dev/null
}

run_make() {
	# 作成されないプラグイン file_xmc を作成しようとするので抑止している。
	${XMINGW}/cross make FILE_XMC="" all install
#	echo skip > /dev/null
}

pre_pack() {
	cp {AUTHORS,COPYING,ChangeLog,LICENSE,NEWS,README} "${INSTALL_TARGET}/." &&
	(cd "${INSTALL_TARGET}" &&
	# 外観を windows 標準にする。
	mkdir -p etc/gtk-2.0 &&
	cat <<EOF > etc/gtk-2.0/gtkrc &&
gtk-theme-name = "MS-Windows"
EOF
	# side-by-side
	echo > bin/gimp-2.8.exe.local &&
	echo > bin/gimp-console-2.8.exe.local)	
}

run_pack_archive() {
	(cd "${INSTALL_TARGET}" &&
	pack_archive "${BINZIP}" bin/*.{exe,dll,local} etc `find lib/gimp -xtype f -not -iname \*.a -and -not -iname \*.la` share/{gimp,icons,locale} [ACLNR]* &&
	pack_archive "${DEVZIP}" bin/gimptool-2.0* include `find lib -xtype f -iname \*.a -or -iname \*.def` lib/pkgconfig share/{aclocal,icons} &&
	store_packed_archive "${BINZIP}" &&
	store_packed_archive "${DEVZIP}")
}


(

set -x

XLIBRARY_SET=${XLIBRARY}/gimp_build_set

#for D in $DEPS; do
#    PATH="/devel/dist/${ARCH}/$D/bin:$PATH"
#    PKG_CONFIG_PATH=/devel/dist/${ARCH}/$D/lib/pkgconfig:$PKG_CONFIG_PATH
#done

run_expand_archive &&
cd "${DIRECTORY}" &&
pre_configure &&
run_configure &&
post_configure &&

pre_make &&
run_make &&

pre_pack &&
run_pack_archive &&

(
(cd app/tests && ${XMINGW}/cross make test-core.exe test-gimpidtable.exe test-save-and-export.exe test-session-2-6-compatibility.exe test-session-2-8-compatibility-multi-window.exe test-session-2-8-compatibility-single-window.exe test-single-window-mode.exe test-tools.exe test-ui.exe test-xcf.exe) &&

TESTSZIP=${MOD}-${VER}-${REV}-tests_${ARCH} &&
pack_archive "${TESTSZIP}" app/tests/*.exe app/tests/{.libs,files,gimpdir,gimpdir-empty,gimpdir-output} tools/test-clipboard.exe tools/.libs/\*test-clipboard\*
) &&

echo success completed.

) 2>&1 | tee ${PWD}/${THIS}.log


echo done.


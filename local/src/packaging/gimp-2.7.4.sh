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
VER=2.7.4
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
	cp build/windows/wilber.ico build/windows/plug-ins.ico &&
	# winbase.h に SetProcessDEPPolicy 関係の定義がない場合に対応する。
	patch -p 1 <<\EOS
--- gimp-2.7.4.orig/SetProcessDEPPolicy.h
+++ gimp-2.7.4/SetProcessDEPPolicy.h
@@ -0,0 +1,7 @@
+#if (_WIN32_WINNT >= 0x0503)
+#ifndef SetProcessDEPPolicy
+#  define PROCESS_DEP_ENABLE 0x00000001
+#  define PROCESS_DEP_DISABLE_ATL_THUNK_EMULATION 0x00000002
+WINBASEAPI BOOL WINAPI SetProcessDEPPolicy (DWORD);
+#endif
+#endif

--- gimp-2.7.4.orig/app/main.c
+++ gimp-2.7.4/app/main.c
@@ -67,8 +67,9 @@
 /* To get PROCESS_DEP_* defined we need _WIN32_WINNT at 0x0601. We still
  * use the API optionally only if present, though.
  */
-#define _WIN32_WINNT 0x0601
+#define _WIN32_WINNT 0x0503
 #include <windows.h>
+#include "SetProcessDEPPolicy.h"
 #include <conio.h>
 #endif
 
--- gimp-2.7.4.orig/libgimp/gimp.c
+++ gimp-2.7.4/libgimp/gimp.c
@@ -84,8 +84,9 @@
 
 #if defined(G_OS_WIN32) || defined(G_WITH_CYGWIN)
 #  define STRICT
-#  define _WIN32_WINNT 0x0601
+#  define _WIN32_WINNT 0x0503
 #  include <windows.h>
+#include "SetProcessDEPPolicy.h"
 #  undef RGB
 #  define USE_WIN32_SHM 1
 #endif
EOS
}

run_configure() {
	# _WIN32_WINNT=0x0503 は XP SP3 （推測）
	CC='gcc -mtune=pentium4 -mthreads -msse -mno-sse2 ' \
	CPPFLAGS="`${XMINGW}/cross --cflags` \
	-DWINVER=0x0503 -D_WIN32_WINNT=0x0503 -DXPM_NO_X \
	-I${XLIBRARY}/gimp-dep/include/noX" \
	LDFLAGS="`${XMINGW}/cross --ldflags` \
	-Wl,--enable-auto-image-base -Wl,-s" \
	CFLAGS="-pipe -O2 -fomit-frame-pointer -ffast-math" \
	${XMINGW}/cross-configure --target=i386-pc-mingw32 --enable-shared --disable-static --enable-mmx --enable-sse --disable-python --without-x --prefix="${INSTALL_TARGET}"
}

post_configure() {
	bash ${XMINGW}/replibtool.sh &&
	# libwmf が -lpng 決め打ちしているのでごまかす。
	# 下は libpng15 を設定している。場所は ${XLIBRARY}/lib 
	mkdir libpng &&
	ln -s ${XLIBRARY}/lib/include/libpng15 libpng/include &&
	mkdir libpng/lib &&
	ln -s ${XLIBRARY}/lib/lib/libpng15.dll.a libpng/lib/libpng.dll.a
}

pre_make() {
	echo skip > /dev/null
}

run_make() {
	# little cms の問題で -Dcdecl=LCMSAPI している。
	# 作成されないプラグイン(mail , file_xmc)を作成しようとするので抑止している。
	${XMINGW}/cross make MAIL="" FILE_XMC="" CFLAGS="-O2 -mtune=pentium4 -msse -mno-sse2 -pipe -fomit-frame-pointer -ffast-math `${XMINGW}/cross --cflags` -Dcdecl=LCMSAPI" LDFLAGS="-lwsock32 -lole32 -Wl,-s `${XMINGW}/cross --ldflags` -L${PWD}/libpng/lib" install
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
	echo > bin/gimp-2.7.exe.local &&
	echo > bin/gimp-console-2.7.exe.local)	
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
return 0
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


#!/bin/bash
# vim: tabstop=4 fileformat=unix fileencoding=utf-8 filetype=sh

# license: Apache v2.0

if [ "" = "${IN_PACKAGE_SCRIPT}" ]
then
	echo "FAIL: \${XMINGW}/package から実行してください。"
	exit 1
fi


# ARCH は package が設定している。
# XLIBRARY_SOURCES は xmingw のための環境変数。 env.sh で設定している。
init_var() {
	XLIBRARY_SET=${XLIBRARY}/gimp_build_set

	# package に返す変数。
	MOD=exiv2
	[ "" = "${VER}" ] && VER=0.27.0-Source
	[ "" = "${REV}" ] && REV=1
	DIRECTORY="${MOD}-${VER}"

	# 内部で使用する変数。
	__ARCHIVEDIR="${XLIBRARY_SOURCES}/libs/pic"
	__ARCHIVE="${MOD}-${VER}"
#	__PATCH_ARCHIVE="${MOD}_${VER}-${PATCH}"

	__BINZIP=${MOD}-${VER}-${REV}-bin_${ARCHSUFFIX}
	__DEVZIP=${MOD}-dev-${VER}-${REV}_${ARCHSUFFIX}
	__TOOLSZIP=${MOD}-${VER}-${REV}-tools_${ARCHSUFFIX}
}

dependencies() {
	cat <<EOS
gettext-runtime
libiconv
expat
zlib
EOS
}

optional_dependencies() {
	cat <<EOS
EOS
}

license() {
	cat <<EOS
GNU GENERAL PUBLIC LICENSE
Version 2, June 1991
EOS
}

run_expand_archive() {
local name
	name=`find_archive "${__ARCHIVEDIR}" ${__ARCHIVE}` &&
	expand_archive "${__ARCHIVEDIR}/${name}"
}

run_patch() {
	patch_adhoc -p 1 <<\EOS
--- exiv2-0.27.0-Source.orig/src/futils.cpp
+++ exiv2-0.27.0-Source/src/futils.cpp
@@ -34,8 +34,8 @@
 #include <sys/types.h>
 #include <sys/stat.h>
 
-#ifdef _MSC_VER
-    #include <Windows.h>
+#ifdef _WIN32
+    #include <windows.h>
     # define S_ISREG(m)      (((m) & S_IFMT) == S_IFREG)
     #include <psapi.h>  // For access to GetModuleFileNameEx
 #elif defined(__APPLE__)
EOS
}

run_configure() {
	${XMINGW}/cross-cmake -G "Unix Makefiles" -H. -B. -DALLOW_IN_SOURCE_BUILD:bool=true -DCMAKE_BUILD_TYPE:string=RELEASE -DCMAKE_INSTALL_PREFIX:string="${INSTALL_TARGET}" \
	"-DCMAKE_C_FLAGS:string=`${XMINGW}/cross --archcflags --cflags` -pipe -O2 -fomit-frame-pointer -ffast-math " \
	"-DCMAKE_CXX_FLAGS:string=`${XMINGW}/cross --archcflags --cflags` -pipe -O2 -fomit-frame-pointer -ffast-math ${OLD_CXX_ABI} " \
	"-DCMAKE_C_FLAGS_RELEASE:string=-DNDEBUG " \
	"-DCMAKE_CXX_FLAGS_RELEASE:string=-DNDEBUG " \
	"-DCMAKE_SHARED_LINKER_FLAGS:string=`${XMINGW}/cross --ldflags` -Wl,--enable-auto-image-base -Wl,-s -Wl,--export-all-symbols" \
	"-DCMAKE_EXE_LINKER_FLAGS:string=-Wl,--allow-multiple-definition -Wl,-s" \
	-DEXIV2_ENABLE_WIN_UNICODE:bool=ON \
	-DEXIV2_BUILD_PO:bool=ON
}

post_configure() {
	# 使用する場合は bash ${XMINGW}/replibtool.sh にオプションを並べる。
	# shared ファイルを作ってくれない場合の対処。
#	bash ${XMINGW}/replibtool.sh shared
	# static なライブラリーのリンクはこうしないと libtool がいろいろ面倒をみてしまう。
#	bash ${XMINGW}/replibtool.sh mix
	# libstdc++ を静的リンクする。
#	bash ${XMINGW}/replibtool.sh static-libgcc
	# 追加で libtool を書き換える場合は replibtool.sh の実行後に行う。
:	bash ${XMINGW}/replibtool.sh shared mix static-libgcc &&
	# .exe まわりで不備があった。
:	sed -i -e's!EXIV2BIN\s*=\s*\(../bin/\|\)$(EXIV2MAIN:.cpp=)!EXIV2BIN = \1$(EXIV2MAIN:.cpp=$(EXEEXT))!' src/Makefile
}

run_make() {
#	${XMINGW}/cross make EXEEXT=".exe" EXIV2COBJ="" all install
	${XMINGW}/cross make all install
}

pre_pack() {
	# ライセンスなどの情報は share/doc/<MOD>/ に入れる。
	install_license_files "${MOD}" COPYING*
}

run_pack() {
	cd "${INSTALL_TARGET}" &&
	pack_archive "${__BINZIP}" bin/*.dll share/doc &&
	pack_archive "${__DEVZIP}" include lib/*.a lib/pkgconfig share/exiv2/cmake &&
	pack_archive "${__TOOLSZIP}" bin/*.{exe,manifest,local} share/locale share/man/man1 &&
	store_packed_archive "${__BINZIP}" &&
	store_packed_archive "${__DEVZIP}" &&
	store_packed_archive "${__TOOLSZIP}"
}




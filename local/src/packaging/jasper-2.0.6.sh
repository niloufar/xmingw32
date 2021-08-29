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
	MOD=jasper
	[ "" = "${VER}" ] && VER=2.0.6
	[ "" = "${REV}" ] && REV=1

	# [2.0.16] アーカイブとフォルダーの名称が変更された。
local __mod="${MOD}"
	if compare_vernum_ge "2.0.16" "${VER}"
	then
		if compare_vernum_ge "2.0.32" "${VER}"
		then
			:
		else
			__mod="${MOD}-version"
		fi
		
	fi
	DIRECTORY="${__mod}-${VER}"


	# 内部で使用する変数。
	__ARCHIVEDIR="${XLIBRARY_SOURCES}/libs/pic"
	__ARCHIVE="${__mod}-${VER}"
#	__PATCH_ARCHIVE="${MOD}_${VER}-${PATCH}"

	__BINZIP=${MOD}-${VER}-${REV}-bin_${ARCHSUFFIX}
	__DEVZIP=${MOD}-dev-${VER}-${REV}_${ARCHSUFFIX}
	__TOOLSZIP=${MOD}-${VER}-${REV}-tools_${ARCHSUFFIX}
}

dependencies() {
	cat <<EOS
EOS
}

optional_dependencies() {
	cat <<EOS
EOS
}

license() {
	cat <<EOS
JasPer License Version 2.0
EOS
}

run_expand_archive() {
local name
	name=`find_archive "${__ARCHIVEDIR}" ${__ARCHIVE}` &&
	expand_archive "${__ARCHIVEDIR}/${name}"
}

run_patch() {
	# [2.0.6] dll 名が liblibjasper.dll になり、
	#  a ファイルも同名であるため不具合が出る。 configure と同じ名前にする。
	patch_adhoc -p 1 <<\EOS
--- jasper-2.0.6.orig/src/libjasper/CMakeLists.txt
+++ jasper-2.0.6/src/libjasper/CMakeLists.txt
@@ -138,6 +138,8 @@
 
 if (UNIX)
 	set_target_properties(libjasper PROPERTIES OUTPUT_NAME jasper)
+elseif (WIN32)
+	set_target_properties(libjasper PROPERTIES OUTPUT_NAME jasper-${JAS_SO_VERSION})
 endif()
 set_target_properties(libjasper PROPERTIES LINKER_LANGUAGE C)
 
EOS
	# [2.0.12] 構成が変わった。パッチは上記と同じ。
	if [ ! 0 -eq $? ]
	then
		sed -i -e 's/set_target_properties(libjasper PROPERTIES OUTPUT_NAME jasper)/set_target_properties(libjasper PROPERTIES OUTPUT_NAME jasper-${JAS_SO_VERSION})/' src/libjasper/CMakeLists.txt
	fi
}

run_configure() {
	${XMINGW}/cross-cmake -G "Unix Makefiles" -H. -B. -DALLOW_IN_SOURCE_BUILD:bool=true -DCMAKE_BUILD_TYPE:string=RELEASE -DCMAKE_INSTALL_PREFIX:string="${INSTALL_TARGET}" \
	"-DCMAKE_C_FLAGS:string=`${XMINGW}/cross --archcflags --cflags` -pipe -O2 -fomit-frame-pointer -ffast-math " \
	"-DCMAKE_CXX_FLAGS:string=`${XMINGW}/cross --archcflags --cflags` -pipe -O2 -fomit-frame-pointer -ffast-math " \
	"-DCMAKE_C_FLAGS_RELEASE:string=-DNDEBUG " \
	"-DCMAKE_CXX_FLAGS_RELEASE:string=-DNDEBUG " \
	"-DCMAKE_SHARED_LINKER_FLAGS:string=`${XMINGW}/cross --ldflags` -Wl,--enable-auto-image-base -Wl,-s -Wl,--export-all-symbols" \
	-DJAS_ENABLE_SHARED:bool=true -DJAS_ENABLE_LIBJPEG:bool=true -DJAS_ENABLE_OPENGL:bool=true
}

post_configure() {
	# shared ファイルを作ってくれない場合の対処。
	# static なライブラリーのリンクはこうしないと libtool がいろいろ面倒をみてしまう。
:	bash ${XMINGW}/replibtool.sh shared mix
}

run_make() {
	${XMINGW}/cross make all install
}

pre_pack() {
	if [ -e "./man" ]
	then
		(cd "${INSTALL_TARGET}" &&
		mkdir -p share &&
		mv man share/.)
	fi
	(cd "${INSTALL_TARGET}" &&
	# [2.0.6] *.dll が lib に入っている。
	mv lib/*.dll bin/.
	# [2.0.6] dll名の調整。
	mv lib/libjasper-*.dll.a lib/libjasper.dll.a)
	return 0
}

run_pack() {
	cd "${INSTALL_TARGET}" &&
	pack_archive "${__BINZIP}" bin/*.dll &&
	pack_archive "${__DEVZIP}" include lib/*.a lib/pkgconfig &&
	pack_archive "${__TOOLSZIP}" bin/*.{exe,manifest,local} share/doc share/man/man1 &&
	store_packed_archive "${__BINZIP}" &&
	store_packed_archive "${__DEVZIP}" &&
	store_packed_archive "${__TOOLSZIP}"
}



